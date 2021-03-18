


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
//recursiveGraphDirectorySearch(input,"",'malifaux').then(console.log.bind(console));

const cheerio = require('cheerio');
const axios = require('axios');

const dropboxUrl = 'https://www.dropbox.com/sh/wicc6rs8kg46bt7/AADCGZEbHvyB6F13D92dM-lZa/Malifaux%20Third%20Edition?dl=0&subfolder_nav_tracking=1';


let GetAllPdfFrom_Recursive = async function(url,name){

    
    return await axios(url)
    .then(response => {
        const html = response.data;
        const $ = cheerio.load(html);
        let targetStartString = 'window["__REGISTER_SHARED_LINK_FOLDER_PRELOAD_HANDLER"].responseReceived("';
        let targetEndString = '")});';
        let start = new String(html).indexOf(targetStartString);
        let baseText = html.slice(start+targetStartString.length);
        let end =baseText.indexOf(targetEndString);
        baseText = baseText.slice(0,end);
        baseText = baseText.split('\\\\u0026').join('&');
        baseText = baseText.split('\\"').join('"');
        baseText = baseText.split('\\"').join('"');
        
     //   baseText = baseText.split('\\').join('');
        
        console.log(`- ${start} -Folder-${name}`);
        fs.writeFile(exportPath + `\\${name}.json`,baseText,() => {});
        let data = JSON.parse(baseText);
        
        let files = data.entries.filter(el => el.file_id !== undefined);
        let folders = data.entries.filter(el => el.folder_id !== undefined);
        console.log(data.entries.map(el => `${el.filename}=>${el.href}`))
        return Promise.all(folders.map( el => GetAllPdfFrom_Recursive(el.href,name + "_" + el.filename)));
        
        
        
    })
    .catch(console.error);
}


console.log(GetAllPdfFrom_Recursive(dropboxUrl,'M3E'));


// pdfTransform.convert({
//   fileName: input + '\\M3E_Arc_Academic_Kudra.pdf', //"./manual/PDF_Converter_ReadME.pdf", // Specify PDF file path here
//   convertTo: "png", // Can be "png" also
//   exportPath,//导出路径
// });

 
