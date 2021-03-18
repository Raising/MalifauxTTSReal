


// const orePosition = require("./libs/ore-position.js").default;

 var fs = require('fs');
// var text2png = require('text2png');
// var path    = require('path');
const pdfTransform = require("pdf-transform-png");


const getMalifauxResource = async (direction,output) => {
  return new Promise((resolve,rejects) => {

    pdfTransform.convert({
      fileName: direction, //"./manual/PDF_Converter_ReadME.pdf", // Specify PDF file path here
      convertTo: "png", // Can be "png" also
      exportPath: output//.split('.pdf').join('.png'),//导出路径
    });
    console.log(direction);
    return resolve({name:direction});
      // fs.readFile(direction, 'utf8', function (err, data) {
      //     console.log(data);
      //     resolve(JSON.parse(data));
      // });
  });
}

  

const recursiveGraphDirectorySearch = async (directory,basePath,name) => {
  let path = basePath !== "" ?basePath + "." + name : name;
  let DPromise = new Promise((resolve,reject) => {
      let gdir = {
          path,
          name,
          childrenDir:[],
          graphs:[]
      };
      fs.readdir(directory, (err, files) => {
          if (err) {throw err;}
          
          Promise.all(files.map(fileName => {
              if (fileName.endsWith(".pdf")){
                  return getMalifauxResource(directory + "\\" + fileName,directory);
              }else{
                  return recursiveGraphDirectorySearch(directory + "\\" + fileName,path,fileName);
              }
          } ))
          .then( results => {
              results.forEach( (result) => {
                  if (result.id === undefined){
                      gdir.childrenDir.push(result);
                  }else{
                      gdir.graphs.push(result);
                  }
              });

              resolve(gdir);
          })
      });
      
  });
  return await DPromise;
}


var input   = __dirname + '\\malifaux-resources';
var exportPath = __dirname + '\\malifaux-resources-refined';
recursiveGraphDirectorySearch(input,"",'malifaux').then(console.log.bind(console));


// pdfTransform.convert({
//   fileName: input + '\\M3E_Arc_Academic_Kudra.pdf', //"./manual/PDF_Converter_ReadME.pdf", // Specify PDF file path here
//   convertTo: "png", // Can be "png" also
//   exportPath,//导出路径
// });

 
