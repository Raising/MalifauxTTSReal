


// const orePosition = require("./libs/ore-position.js").default;

 var fs = require('fs');
// var text2png = require('text2png');
// var path    = require('path');
const pdfTransform = require("pdf-transform-png");




var allInfoInput = __dirname + '\\prototypes\\OfficialModelInformationMalifaux.json';
var allBagInput = __dirname + '\\prototypes\\AllBreachsideReferences.json';
var allBagOutPut = __dirname + '\\prototypes\\AllBreachSideReferenceCards.json';

var referenceModelPrototyInput   = __dirname + '\\prototypes\\reference-card-prototype.json';
const getMalifauxBag = async (direction) => {
    let MalifauxModelsInfo =  await new Promise((resolve,rejects) => {
        fs.readFile(allInfoInput, 'utf8', function (err, data) {
            resolve(JSON.parse(data));
        });
    });

    let BreachsideData = await new Promise((resolve,rejects) => {
        fs.readFile(direction, 'utf8', function (err, data) {
            let jsonBox =JSON.parse(data);
            resolve(jsonBox);
        });
    });

    figurineData = {};

    BreachsideData.ObjectStates[0].ContainedObjects
    .map(container => container.ContainedObjects[0])
    .map(container => container.ContainedObjects.filter(pack => pack.Nickname.includes("HUD"))[0].ContainedObjects)
    .forEach( figurineCollection => figurineCollection.forEach(figurine => {
        let modelInfo = MalifauxModelsInfo.models[figurine.Nickname];
        figurineData[figurine.Nickname] = {
            transparentImage : figurine.CustomImage.ImageURL,
            imageScale :  figurine.CustomImage.ImageScalar,
            name : figurine.Nickname,
            modelScale : figurine.Transform.scaleX,
            stats: modelInfo.stats,
            base: modelInfo.base,
            factions:modelInfo.factions,
            cardFronts: modelInfo.fileNames.frontJPGs,
            cardBack: modelInfo.backJPG,
            modelInfo,
        };
    }));


    // console.log(figurineData);


    //console.log(figurineData);
    // BagData.ObjectStates[0].ContainedObjects.forEach((factionBag,factionIndex) => {
        
    //     factionBag.ContainedObjects.forEach((figurine,figIndex) => {
    //         let newReferenceCard = JSON.parse(referenceModelPrototype);
    //         newReferenceCard.Nickname = figurine.Nickname;
    //         newReferenceCard.Description = figurine.Description;
    //         newReferenceCard.CustomImage.ImageURL = figurine.CustomImage.ImageURL;
    //         newReferenceCard.CustomImage.ImageSecondaryURL = figurine.CustomImage.ImageSecondaryURL;
            
    //         BagData.ObjectStates[0].ContainedObjects[factionIndex].ContainedObjects[figIndex] = newReferenceCard;
    //     })
    // });

    // fs.writeFile(allBagOutPut,JSON.stringify(BagData),() => {
       
    //  });
}

getMalifauxBag(allBagInput);