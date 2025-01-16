# SGB Attribute Export from Aseprite
# Asepriteからスーパーゲームボーイのアトリビュート書き出す
What is a Super Game Boy Attribute?

SGB attributes are areas on the screen that can be apply 1 of any 4 color palettes stored on the Super Nintendo. They are way give SGB compatible
games their ability to have more than 4 colors on screen at once. 

スーパーゲームボーイのアトリビュートって何ですか？

スーパーゲームボーイのアトリビュートはスーパーファミコンの中にカラーパレットをぬる３画面の上に辺です。スーパーゲームボーイは四つカラーパレットがあります。この
カラーパレットのおかげで普通に白黒ゲームはカラフルになります。

## How to use:
## 使い方：

To export data, you must first use Aseprite's "slice" feature to create rectangular areas. These areas will correspond to the different color
palettes that will be applied. You don't have to be precise when drawing your slices. 

書き出す前、Asepriteの「スライス」を作らなければなりません。スライスはスーパーゲームボーイと言えばアトリビュートになります。スライスは適当に書いてもいいですよ。

![](https://github.com/Bofner/SGB-Attribute-Export-from-Aseprite/blob/main/images/slices.jpg)

Select the proper script.

正しいスクリプトを選びます。

![](https://github.com/Bofner/SGB-Attribute-Export-from-Aseprite/blob/main/images/script.jpg)

Select the SGB color palette you want to apply to the selected slice. Go through all slices, and a .inc file with the same name as the Aseprite file
will be generated containing the raw data that can be sent to the SGB.

一つずつスライスの欲しいカラーパレットを選びます。終わったらAsepriteファイルと同じ名前の生データがある.incファイルは作られます。

![](https://github.com/Bofner/SGB-Attribute-Export-from-Aseprite/blob/main/images/select.jpg)

You can now turn screens like this...

こう言うスクリーンは...

![](https://github.com/Bofner/SGB-Attribute-Export-from-Aseprite/blob/main/images/Real%20SGB%20default.jpg)

into screens like this!

...こんな感じになります！

![](https://github.com/Bofner/SGB-Attribute-Export-from-Aseprite/blob/main/images/Real%20SGB%20Color.jpg)


## NOTES:
## ノート：
For now this only supports the LIN and BLK attribute types. Perhaps in the future I will add CHR and DIV support as well. 
The BLK feature is also not fully robust, as it only allows for creating BLK attributes with color changes being applied
within the boundaries of your rectangle. This may also be updated later. 

とりあえずBLKとLINのアトリビュートだけ作れます。BLKのアトリビュートも中の色だけ選びます。僕はいつかBLKの全部のサポートとDIVとCHRサポートを付け足すかもしれません。
