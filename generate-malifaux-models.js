


// const orePosition = require("./libs/ore-position.js").default;

 var fs = require('fs');
// var text2png = require('text2png');
// var path    = require('path');
const pdfTransform = require("pdf-transform-png");



var allBagInput = __dirname + '\\prototypes\\AllMalifauxModels.json';
var allBagOutPut = __dirname + '\\prototypes\\AllMalifauxReferenceCards.json';

var referenceModelPrototyInput   = __dirname + '\\prototypes\\reference-card-prototype.json';
const getMalifauxBag = async (direction) => {
    let referenceModelPrototype =  await new Promise((resolve,rejects) => {
        fs.readFile(referenceModelPrototyInput, 'utf8', function (err, data) {
            resolve(data);
        });
    });

    let BagData = await new Promise((resolve,rejects) => {
        fs.readFile(direction, 'utf8', function (err, data) {
            let jsonBox =JSON.parse(data);
            resolve(jsonBox);
        });
    });

    BagData.ObjectStates[0].ContainedObjects.forEach((factionBag,factionIndex) => {
        
        factionBag.ContainedObjects.forEach((figurine,figIndex) => {
            let newReferenceCard = JSON.parse(referenceModelPrototype);
            newReferenceCard.Nickname = figurine.Nickname;
            newReferenceCard.Description = figurine.Description;
            newReferenceCard.CustomImage.ImageURL = figurine.CustomImage.ImageURL;
            newReferenceCard.CustomImage.ImageSecondaryURL = figurine.CustomImage.ImageSecondaryURL;
            
            BagData.ObjectStates[0].ContainedObjects[factionIndex].ContainedObjects[figIndex] = newReferenceCard;
        })
    });

    fs.writeFile(allBagOutPut,JSON.stringify(BagData),() => {
       
     });
}

getMalifauxBag(allBagInput);
// const recursiveGraphDirectorySearch = async (directory,basePath,name) => {
//     let path = basePath !== "" ?basePath + "." + name : name;
//     let DPromise = new Promise((resolve,reject) => {
//         let gdir = {
//             path,
//             name,
//             childrenDir:[],
//             graphs:[]
//         };
//         fs.readdir(directory, (err, files) => {
//             if (err) {throw err;}
            
//             Promise.all(files.map(fileName => {
//                 if (fileName.endsWith(".json")){
//                     return getFlowGraphFromDB(directory + "/" + fileName);
//                 }else{
//                     return recursiveGraphDirectorySearch(directory + "/" + fileName,path,fileName);
//                 }
//             } ))
//             .then( results => {
//                 results.forEach( (result:any) => {
//                     if (result.id === undefined){
//                         gdir.childrenDir.push(result);
//                     }else{
//                         gdir.graphs.push(result);
//                     }
//                 });

//                 resolve(gdir);
//             })
//         });
        
//     });
//     return await DPromise;
// }



// var input   = __dirname + '\\malifaux-resources';
// var exportPath = __dirname + '\\malifaux-resources-refined';
// recursiveGraphDirectorySearch(input,"",'malifaux').then(console.log.bind(console));


// // pdfTransform.convert({
// //   fileName: input + '\\M3E_Arc_Academic_Kudra.pdf', //"./manual/PDF_Converter_ReadME.pdf", // Specify PDF file path here
// //   convertTo: "png", // Can be "png" also
// //   exportPath,//导出路径
// // });

 
