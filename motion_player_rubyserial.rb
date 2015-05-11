# -*- coding: utf-8 -*-
require 'rubygems'
require 'rubyserial'
require 'json'

# コマンド
COMMAND_ST = 0xff
COMMAND_ST_I2C = 0x0c
COMMAND_OP_ANGLE = 0x6f
COMMAND_OP_PWM = 0x70
COMMAND_OP_SET_VID = 0x73
COMMAND_OP_WALK = 0x74

# シリアルポート
if ARGV[0].nil?
  serial_port = '/dev/tty.SBDBT-0009dd40dc14-SPP'
else
  serial_port = ARGV[0]
end
serial_bautrate = 115200

# モーションデータ
if ARGV[1].nil?
  motion_file = 'motions.json'
else
  motion_file = ARGV[1]
end

# シリアル等の外部とのデータのやりとりについて1バイトで行う
Encoding.default_external = 'ASCII-8BIT'

# シリアル接続
print "Connecting serial port..."
begin
  #$sp = SerialPort.new(serial_port, serial_bautrate)
  $sp = Serial.new(serial_port, serial_bautrate)
rescue => e
  STDERR.puts 'cannot open port.'
  STDERR.puts e.to_s
  exit 1
end

puts 'connected.'

# モーションデータの読み込み
print "Loading motion file..."
begin
  motion_file_data = open(motion_file).read
rescue => e
  STDERR.puts 'cannot open motion file.'
  STDERR.puts e.to_s
  exit 1
end

puts 'loaded.'

# モーションデータのJSON解釈
print "Parsing JSON data..."
begin
  motion_data = JSON.parse(motion_file_data);
rescue => e
  STDERR.puts 'JSON error in  motion file.'
  STDERR.puts e.to_s
  exit 1
end

motions = motion_data["motion_list"].sort_by{|k, v| v}
print motions.length, " motions loaded\n"

# シリアル受信スレッド立ち上げ
Thread.new{
  buffer = []
  loop do
    recieve = $sp.getbyte
    if !recieve.nil?
      if recieve.to_s(16) == "ff"
        buffer = []
      end
      buffer.push(recieve.to_s(16))
      if buffer.length > 3
        if buffer.length == buffer[2].to_i
          print "< ", buffer.join(" "), "\n"
        end
      end
    end
  end
}

# サーボの角度変更コマンド生成
def make_multi_servo_angle_command(angle_data, time)
  if time > 254
    time = 254
  end
  command_data = []
  command_data.push COMMAND_ST
  command_data.push COMMAND_OP_ANGLE
  command_data.push 0x00 #LN
  command_data.push time #CYCここでは固定値
  angle_data.each{|sid, angle|
    command_data.push sid.to_i

    # 角度は2バイトなので、ビットシフト処理などを行う(コマンドリファレンス参照)
    deg = (angle * 10).round
    command_data.push (deg << 1) & 0x00ff #DEG_L
    command_data.push (((deg << 1) >> 8) << 1) & 0x00ff #DEG_H
  }
  command_data.push 0x00 #sum

  command_data[2] = command_data.size

  # チェックサム生成
  sum = 0
  for data in command_data
    sum ^= data
  end
  command_data[command_data.size - 1] = sum

  return command_data
end

# VID設定コマンド生成
def make_set_vid_command(vid, status)
  command_data = []
  command_data.push COMMAND_ST
  command_data.push COMMAND_OP_SET_VID
  command_data.push 0x00 #LN
  command_data.push vid #VID
  command_data.push status #VDT
  command_data.push 0x00 #sum

  command_data[2] = command_data.size

  # チェックサム生成
  sum = 0
  for data in command_data
    sum ^= data
  end
  command_data[command_data.size - 1] = sum

  return command_data
end

# PWM変更コマンド生成
def make_pwm_command(pin, duty)
  command_data = []
  command_data.push COMMAND_ST
  command_data.push COMMAND_OP_PWM
  command_data.push 0x00 #LN
  command_data.push pin
  command_data.push ((duty / 4) / 256).round
  command_data.push ((duty / 4) % 256)
  command_data.push 0x00 #sum

  command_data[2] = command_data.size

  # チェックサム生成
  sum = 0
  for data in command_data
    sum ^= data
  end
  command_data[command_data.size - 1] = sum

  return command_data
end

# PWM変更コマンド生成
def make_i2c_pt_command(i2c_address, reg_address, i2c_data)
  command_data = []
  command_data.push COMMAND_ST_I2C
  command_data.push 0x00 #LN
  command_data.push i2c_address
  command_data.push reg_address
  command_data.push i2c_data
  command_data.push 0x00 #sum

  command_data[1] = command_data.size

  # チェックサム生成
  sum = 0
  for data in command_data
    sum ^= data
  end
  command_data[command_data.size - 1] = sum

  return command_data
end


# コマンド送信（データの内容チェックなし）
def send_data(command_data)
  #p command_data
  data_str = ""
  data_array =[]
  for data in command_data
    data_str << data.chr
    data_array.push data.to_s(16)
  end
  $sp.write data_str
  print "> ", data_array.join(" "), "\n"
end

# PWMの利用開始
puts 'use PWM...'
send_data(make_set_vid_command(0x05, 0x01));
sleep 0.5

puts ''

# メインループ
loop do
  print "[motions]\n"
  for num in 0..(motions.length - 1) do
    print num, ": ", motions[num]["name"], "\n"
  end
  print '0-', motions.length - 1, "(99:exit): "
  key = STDIN.gets.to_i
  if (0..(motions.length - 1)).include? key
    print motions[key]["name"], "\n"
    motions[key]["pose_list"].each{|pose_data|
      print "pose:", pose_data["pose_id"], "\n"
      time = (motions[key]["time_multiple"] * pose_data["time"] * 100).round
      send_data(make_pwm_command(0x07, (750 + (1500 * pose_data["led"] / 100.0).round)))
      sleep 0.1
      if !pose_data["sound"].nil?
        send_data(make_i2c_pt_command(0x09, 0x70, pose_data["sound"]))
        sleep 0.1
      end
      send_data(make_multi_servo_angle_command(motion_data["servo_offset"].merge(pose_data["servo"]){|key, v0, v1|v0 + v1}, time))
      sleep time / 100.0
    }
  elsif key == 99
    $sp.close
    puts 'connection closed.'
    exit 0
  end
end

$sp.close
