


const orePosition = require("./libs/ore-position.js").default;
var express = require('express');
var fs = require('fs');
var text2png = require('text2png');

var app = express();
var cant = 0;
var currentPos = {x:0,y:0,z:0};
let posImage = text2png(currentPos.x + "\n" + currentPos.y + "\n" + currentPos.z , {color: 'white'});



app.get('/:x/:y/:z/test.png', function (req, res) {
  console.log("imageREquest" + cant++);
  currentPos = {x:req.params.x , y:req.params.y ,z:req.params.z};
  oreImage = text2png( orePosition().map((pos) => pos ? pos.dis : "" ).join("\n") ||"no DAta"  , {color: 'white'});

  

  res.set({'Content-Type': 'image/png'});
  res.send(oreImage);
});

app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});

orePosition();
// setTimeout(()=> {
//   screenshot({ filename: 'shot.png',format: 'png' }).then((imgPath) => {
//     processScanImage(imgPath);
//   });
   
// },1000)
