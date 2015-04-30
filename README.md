# RubyVSidoSample

## これは何？
[アスラテック株式会社](http://www.asratec.co.jp/ "アスラテック株式会社")のロボット制御マイコンボード「[V-Sido CONNECT RC](http://www.asratec.co.jp/product/connect/rc/ "V-Sido CONNECT RC")」をコントロールするためのRubyのサンプルコードです。  
[V-Sido Developerサイトの技術資料](https://v-sido-developer.com/learning/connect/connect-rc/ "V-Sido Developerサイトの技術資料")に公開されている情報を元に個人が作成したもので、アスラテック社公式のツールではありません。  

## 誰が作ったの？
アスラテック株式会社に勤務する今井大介(Daisuke IMAI)が個人として作成しました。

## 使い方
$ gem install serialport  
で、シリアルポートのライブラリを導入してください。  

$ ruby sample.rb [シリアルポートデバイス]  
(引数がない場合は、スクリプト中の規定値になります)  

特にエラーなく接続できた場合、キーボードの1〜4を入力しreturnすると動きます。  
1: 首を−30度の位置に動かす  
2: 首を0度の位置に動かす  
3: 首を30度の位置に動かす  
4: 前進  
5: 終了

画面に表示されるレスポンスは以下のとおりです。  
\> は送信したデータです。  
< は受信したデータです。  

※動作確認は、OS X 10.10.3上でruby 2.1.5p273にて行っています。

## 免責事項
一応。  
  
このサンプルコードを利用して発生したいかなる損害についても、アスラテック株式会社ならびに今井大介は責任を負いません。自己責任での利用をお願いします。

## ライセンス
このサンプルコードは、GNU劣等GPLで配布します。  
  
Copyright (C)2015 Daisuke IMAI \<<hine.gdw@gmail.com>\>  

このライブラリはフリーソフトウェアです。あなたはこれを、フリーソフトウェア財団によって発行されたGNU 劣等一般公衆利用許諾契約書(バージョン2.1か、希望によってはそれ以降のバージョンのうちどれか)の定める条件の下で再頒布または改変することができます。  

このライブラリは有用であることを願って頒布されますが、*全くの無保証*です。商業可能性の保証や特定の目的への適合性は、言外に示されたものも含め全く存在しません。詳しくはGNU 劣等一般公衆利用許諾契約書をご覧ください。  

あなたはこのライブラリと共に、GNU 劣等一般公衆利用許諾契約書の複製物を一部受け取ったはずです。もし受け取っていなければ、フリーソフトウェア財団まで請求してください(宛先は the Free Software Foundation, Inc., 59Temple Place, Suite 330, Boston, MA 02111-1307 USA)。  


Copyright (C) 2015 Daisuke IMAI \<<hine.gdw@gmail.com>\>

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.  

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.  

You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  

