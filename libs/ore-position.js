const { Image ,gradientFilter} = require("image-js");
const screenshot = require("screenshot-desktop");
const imageHeight = 430;
let lastOreDistances = [];

setInterval(()=> {
  screenshot({ filename: 'shot.png',format: 'png' }).then((imgPath) => {
    processScanImage(imgPath);
  });
},1000);

const processScanImage = (imgPath)=> {
    let basecrop;
    Image.load(imgPath)
    .then(function (image) {
        var baseCrop = crop(image,10);
        baseCrop.save('baseCrop.png');
  
        var oreCurrentPositionsImage = crop(image,0)
        .subtractImage(baseCrop,{})
        //.gaussianFilter({radius:1,sigma:0.1})
        .medianFilter({radius:2});
  
        oreCurrentPositionsImage.save('crop.png')
        let oreDistances = getOreDistances(oreCurrentPositionsImage);
        console.log(oreDistances
        .map(color => color.hue+"_"+color.sat+"_"+color.light+".Dis:"+ color.dis + "-S-"+color.spread )
           );

        if (oreDistances.length > 2 && oreDistances.length < 6){ //TODO DETECT when is a properReading
          lastOreDistances = oreDistances;
        }

        
       
        
        
        
        // gradientFilter()
        // cropped.subtract(basecolor).save('colorRemoved.png');
        //match
  
        // var mask = oreCurrentPositionsImage
        // .subtractImage(baseCrop,{})
        // .grey()
        // .mask({threshold:0.02})
        // mask.save('mask.png');
        // oreCurrentPositionsImage.paintMasks({masks:mask})
        // .save('diffCrop.png');

      });
    }
  
    const getOreDistances = (oreImage) => {
      var singleLineOreImg = oreImage
      .crop({x:2,width:1});
      singleLineOreImg.save('singleLine.png');
      var [hueImg,satImg,lightImg] = singleLineOreImg
      .hsl()
      .split();
  
      var oreDetected = [];
      var lastPixel = {hue:0,sat:0,light:0};
  
      for (var i = 0; i < imageHeight;i++){
        let pixel = {hue:hueImg.getValue(i,0),sat:satImg.getValue(i,0),light:lightImg.getValue(i,0),pos:i,dis:Math.round((imageHeight - i)*500/imageHeight,2)};
        if (pixel.light < 20){
          pixel = {hue:0,sat:0,light:0,pos:i,dis:Math.round((imageHeight - i)*500/imageHeight,2)};
        }
        
        let gradient = {hue:pixel.hue-lastPixel.hue,sat:pixel.sat-lastPixel.sat,light:pixel.light-lastPixel.light};
  
        if (pixel.light>0){
          if ((Math.abs(gradient.hue) + Math.abs(gradient.sat/5)) > 15){
            oreDetected.push([pixel])
          }else{
            oreDetected[oreDetected.length-1].push(pixel);
          }
        }
        lastPixel = pixel;
      }
      return oreDetected
      .map( oreColors => oreColors
        .reduce((acc,color)=> {
          if(color.light > acc.light)return {...color,spread:oreColors.length};
          return acc
        },{hue:0,sat:0,light:0,pos:0,spread:oreColors.length} )
      );
     
    }
  
    const crop = (image,xoffset) => {
      let cropped = image.crop({
        x:1427 + xoffset,
        width:5,
        
        y:150,
        height:imageHeight,
      });
      return cropped;//.gaussianFilter({radius:1,sigma:0.1});
    }
   

    exports.default = function () {
      return lastOreDistances;
      };
  