# Description:
#   Following on from the spudme theme, this is NOT racist :)
#
# Commands:
#   hubot whey-aye man
#   hubot fog on the tyne
#
# Author:
#  pstack

geordies = [
  "http://static.squarespace.com/static/5011abbee4b0253ab1204ac0/t/511b569ae4b0dcc6d89c9db5/1360746138704/GAzza.jpeg",
  "http://www.assetstorage.co.uk/AssetStorageService.svc/GetImageFriendly/721463860/339/422/0/0/1/80/ResizeBestFit/0/FRU/883FBEAF0426B94D8793618077E9D342/geoff-and-spuggy.jpg",
  "http://www.bbc.co.uk/tyne/content/images/2006/08/21/ant_and_dec_show_470x353.jpg",
  "http://www.starstills.com/product_images/m/ss2237118_-_photograph_of_jimmy_nail_as_leonard_jeffrey_oz_osborne_from_auf_wiedersehen_pet_available_in_4_sizes_framed_or_unframed_buy_now_at_starstills__91430.jpg",
  "http://i2.cdnds.net/13/31/618x579/uktv-auf-wiedersehen-pet.jpg",
  "http://eil.com/images/main/Lindisfarne+-+Fog+On+The+Tyne+%5BRevisited%5D+-+5%22+CD+SINGLE-494879.jpg",
  "https://s3.amazonaws.com/uploads.hipchat.com/64658/539392/B3WShhDa0HOiKZ3/upload.png",
  "http://i2.cdnds.net/11/17/reality_tv_geordie_shore_jay.jpg"
]

module.exports = (robot) ->

  robot.respond /(whey-aye man|fog on the tyne)/i, (msg) ->
    msg.send msg.random geordies

  robot.respond /(can you translate for ryan?)/i, (msg) ->
    msg.send "I have no idea what he's saying. I cannot speak Geordie"
