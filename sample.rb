# -*- coding: utf-8 -*-
require 'rubygems'
require 'serialport'

# コマンド
COMMAND_ST = 0xff
COMMAND_OP_ANGLE = 0x6f
COMMAND_OP_WALK = 0x74

# シリアル設定
serial_port = ARGV[0]
p serial_port
exit 0
#serial_port = '/dev/tty.SBDBT-0009dd40dc14-SPP'
serial_bautrate = 115200

# シリアル等の外部とのデータのやりとりについて1バイトで行う
Encoding.default_external = 'ASCII-8BIT'

# シリアル接続
$sp = SerialPort.new(serial_port, serial_bautrate)

# サーボの角度変更コマンド生成
def make_angle_command(sid, angle)
  command_data = []
  command_data.push COMMAND_ST
  command_data.push COMMAND_OP_ANGLE
  command_data.push 0x00 #LN
  command_data.push 0x02 #CYCここでは固定値
  command_data.push sid

  # 角度は2バイトなので、ビットシフト処理などを行う(コマンドリファレンス参照)
  deg = angle * 10
  command_data.push (deg << 1) & 0x00ff #DEG_L
  command_data.push (((deg << 1) >> 8) << 1) & 0x00ff #DEG_H

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

# 歩行コマンド生成
def make_walk_command(speed, turn)
  command_data = []
  command_data.push COMMAND_ST
  command_data.push COMMAND_OP_WALK
  command_data.push 0x00 #LN
  command_data.push 0x00 #WAD(現在は0で固定)
  command_data.push 0x02 #WLN(speedとturnの2バイト送信する)

  # 速度ならびに旋回は-100〜100を0〜200に変換する
  command_data.push speed + 100
  command_data.push turn + 100

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

# コマンド送信（データの内容チェックなし）
def send_data(command_data)
  data_str = ""
  for data in command_data
    data_str << data.chr
  end
  $sp.puts data_str
  $sp.flush
  print("> ")
  for data in command_data
    print data.chr.unpack("H*")[0]
    print " "
  end
  print "\n"
end

# シリアル受信スレッド
Thread.new{
  buffer = []
  loop do
    recieve = $sp.getc
    if recieve.unpack("H*")[0] == "ff"
      buffer = []
      print("< ")
    end
    buffer.push(recieve.unpack("H*")[0])
    print(recieve.unpack("H*")[0])
    if buffer.length > 3
      if buffer.length == buffer[2].to_i
        print("\n")
      else
        print(" ")
      end
    else
      print(" ")
    end
  end
}

# メインループ
loop do
  key = gets.chomp.to_i
  # 首振り(サーボID:2)
  if (1..3).include? key
    send_data(make_angle_command(2, (key - 2) * 30))
    #sleep(1)
  end
  # 歩行
  if key == 4
    send_data(make_walk_command(50, 0))
    #sleep(1)
  end
end

$sp.close
