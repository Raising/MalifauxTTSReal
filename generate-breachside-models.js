


// const orePosition = require("./libs/ore-position.js").default;

 var fs = require('fs');
// var text2png = require('text2png');
// var path    = require('path');
const pdfTransform = require("pdf-transform-png");





// var facitonContainerInput = __dirname + '\\prototypes\\faction-container.json';




var allBagOutPut = __dirname + '\\output\\BreachSideCardBox.json';


var inputPath = {
    upgradeCardPrototype: __dirname + '\\prototypes\\upgrade-card-prototype.json',
    referenceModelPrototype: __dirname + '\\prototypes\\reference-card-prototype.json',
    boxContainerPrototype: __dirname + '\\prototypes\\box-container.json',

    allModelData : __dirname + '\\prototypes\\all-models-data.json',
    
    officialModelInfo: __dirname + '\\prototypes\\OfficialModelInformationMalifaux.json',
    officialUpgradesInfo: __dirname + '\\prototypes\\OfficialUpgradeInformationMalifaux.json',

    allBagInput: __dirname + '\\prototypes\\AllBreachsideReferences.json',
} 

var loadFile = async (filePath,isJson) => {
    return await new Promise((resolve,rejects) => {
        fs.readFile(filePath, 'utf8', function (err, data) {
            resolve(isJson ? JSON.parse(data) :data);
        });
    });
}
const getMalifauxBag = async () => {
    let referenceModelPrototype =  await loadFile(inputPath.referenceModelPrototype,false);
    let upgradeCardPrototype =  await loadFile(inputPath.upgradeCardPrototype,false)
    let boxContainer =   await loadFile(inputPath.boxContainerPrototype,true)

    let MalifauxModelsInfo =  await loadFile(inputPath.officialModelInfo,true);
    let MalifauxUpgradesInfo =   await loadFile(inputPath.officialUpgradesInfo,true);

    let figurineData =  await loadFile(inputPath.allModelData,true);

    

    factionReferences = {
        all:[],
        upgrades:[],
    };

    Object.values(figurineData).forEach( figurine => {
        index = 1;
        MalifauxModelsInfo.models[figurine.name].fileNames.frontJPGs.forEach( (officialDataImage) => {
        
            let cardFrontImage = `https://firebasestorage.googleapis.com/v0/b/m3e-crew-builder-22534.appspot.com/o/${encodeURIComponent(officialDataImage)}?alt=media`
            let referenceCard = createReferenceCard({...figurine,cardFront:cardFrontImage, name: index == 1 ? figurine.name : figurine.name + " " + index},referenceModelPrototype);
            figurine.factions.forEach(factionName => {
                if ( factionReferences[factionName] === undefined){
                    factionReferences[factionName] = [];
                }
                factionReferences[factionName].push(referenceCard);
            });
            referenceCard = createReferenceCard({...figurine,cardFront:cardFrontImage, name: index == 1 ? figurine.name : figurine.name + " " + index},referenceModelPrototype,true);
            factionReferences.all.push(referenceCard);
            
            index++;

        });

    
    });


    Object.values(MalifauxUpgradesInfo).forEach( upgrade => {
        let upgradeCard =createUpgradeCard(upgrade,upgradeCardPrototype);
        for (let i = 0; i<upgrade.rarity;i++){
            factionReferences.upgrades.push(upgradeCard);
        }
    });
 
    boxContainer.ObjectStates[0].ContainedObjects.forEach( childContainer => {
        childContainer.ContainedObjects = factionReferences[factionTraslation[childContainer.Nickname]];
    })
    await fs.writeFile(allBagOutPut,JSON.stringify(boxContainer),() => {});
   // await fs.writeFile(allModelData,JSON.stringify(figurineData),() => {});
    console.log("done");
}

getMalifauxBag();

const factionTraslation = {
    "OUTCAST" :"Outcasts",
    "BAYOU" :"Bayou",
    "GUILD" :"Guild",
    "NEVERBORN" :"Neverborn", 
    "TEN THUNDERS" : "Ten Thunders",  
    "ARCANIST" : "Arcanists", 
    "EXPLORER SOCIETY" :"Explorer's Society",
    "RESURRECTIONISTS" :"Resurrectionist",
    "ALL": "all",
    "UPGRADES": "upgrades",
}

 
const createReferenceCard= (figData,referenceCardPrototype,onlyName = false) => {
    let referenceCard = JSON.parse(referenceCardPrototype);
    referenceCard.CustomImage.ImageURL = figData.cardFront
    referenceCard.CustomImage.ImageSecondaryURL = figData.cardBack
    referenceCard.Nickname = onlyName ? figData.name : `${figData.name}\r\n${figData.keywords.join(',')}`;
    referenceCard.Description = `${figData.name}\r\n${figData.keywords.join(',')}`;

    referenceCard.LuaScript = referenceCard.LuaScript.replace('[BASE_SCALE]',figData.baseScale);
    referenceCard.LuaScript = referenceCard.LuaScript.replace('[HEALTH]',figData.health);
    referenceCard.LuaScript = referenceCard.LuaScript.replace('[IMAGE_SCALE]',figData.imageScale);
    referenceCard.LuaScript = referenceCard.LuaScript.replace('[MODEL_IMAGE]',figData.modelImage);
    referenceCard.LuaScript = referenceCard.LuaScript.replace('[MODEL_SCALE_X]',figData.modelScaleX);
    referenceCard.LuaScript = referenceCard.LuaScript.replace('[MODEL_SCALE_Y]',figData.modelScaleY);
    referenceCard.LuaScript = referenceCard.LuaScript.replace('[NICKNAME]',figData.name);

    return referenceCard;
}

 
const createUpgradeCard= (upgradeData,upgradeCardPrototype) => {
    let referenceCard = JSON.parse(upgradeCardPrototype);

    let image = `https://firebasestorage.googleapis.com/v0/b/m3e-crew-builder-22534.appspot.com/o/${encodeURIComponent(upgradeData.fileNames.frontJPGs[0])}?alt=media`;
    referenceCard.CustomImage.ImageURL = image;
    referenceCard.CustomImage.ImageSecondaryURL = image;
    referenceCard.Nickname = upgradeData.name;
    referenceCard.Description = `${upgradeData.name}\r\n${upgradeData.factions.join(',')}`;

    return referenceCard;
}


const retrieverFromTTSObject = () => {
       //factionContainer.ObjectStates[0].ContainedObjects = [];
    // figurineData = {};
    // let missmatch = 0;
    // BreachsideData.ObjectStates[0].ContainedObjects
    // .map(container => container.ContainedObjects[0])
    // .map(container => container.ContainedObjects.filter(pack => pack.Nickname.includes("HUD"))[0].ContainedObjects)
    // .forEach( figurineCollection => {
    //     //remove bags

    //     figurineCollection.forEach(figurine => {
    //     let modelInfo = MalifauxModelsInfo.models[figurine.Nickname];
    //     if (modelInfo === undefined){
    //         console.log(figurine.Nickname);
    //         modelInfo = {fileNames:{}};
    //         missmatch++;
    //     }
    //     let baseScale= modelInfo.base / 25;
    //     figurineData[figurine.Nickname] = {
    //         modelImage : figurine.CustomImage.ImageURL,
    //         imageScale : figurine.CustomImage.ImageScalar,
    //         name : figurine.Nickname,
    //         health: modelInfo.stats.health,
    //         //base: modelInfo.base,
    //         baseScale,
    //         modelScaleX:Math.round( 0.45 * baseScale *100)/100,
    //         modelScaleY:Math.round( 0.45 * baseScale *100)/100,
    //         //https://firebasestorage.googleapis.com/v0/b/m3e-crew-builder-22534.appspot.com/o/cards%2FArcanists%2FSandeep-Desai-front-0.jpg?alt=media
    //         cardFront: `https://firebasestorage.googleapis.com/v0/b/m3e-crew-builder-22534.appspot.com/o/${encodeURIComponent(modelInfo.fileNames.frontJPGs[0])}?alt=media`  ,
    //         cardBack:  `https://firebasestorage.googleapis.com/v0/b/m3e-crew-builder-22534.appspot.com/o/${encodeURIComponent(modelInfo.fileNames.backJPG)}?alt=media`  ,
    //         factions:modelInfo.factions,
    //         keywords: modelInfo.keywords,
    //         // modelScale : figurine.Transform.scaleX,
    //         //modelInfo,
    //     };

    //     let referenceCard = createReferenceCard( figurineData[figurine.Nickname],referenceModelPrototype);
    //     modelInfo.factions.forEach(factionName => {
    //         if ( factionReferences[factionName] === undefined){
    //             factionReferences[factionName] = [];
    //         }
    //         factionReferences[factionName].push(referenceCard);
    //     });
    //     referenceCard = createReferenceCard( figurineData[figurine.Nickname],referenceModelPrototype,true);
    //     factionReferences.all.push(referenceCard);
    
    //     })
    // });

    
    // Object.values(figurineData).forEach( figData => {
    //     let referenceCard = JSON.parse(referenceModelPrototype);
    //     referenceCard.CustomImage.ImageURL = figData.cardFront
    //     referenceCard.CustomImage.ImageSecondaryURL = figData.cardBack
    //     referenceCard.Nickname = figData.name
    //     referenceCard.Description = `${figData.name}\r\n${figData.keywords.join(',')}`;
    //     referenceCard.LuaScript.replace([])
    //      referenceCard.LuaScript = referenceCard.LuaScript.replace('[BASE_SCALE]',figData.baseScale);
    //      referenceCard.LuaScript = referenceCard.LuaScript.replace('[HEALTH]',figData.health);
    //      referenceCard.LuaScript = referenceCard.LuaScript.replace('[IMAGE_SCALE]',figData.imageScale);
    //      referenceCard.LuaScript = referenceCard.LuaScript.replace('[MODEL_IMAGE]',figData.modelImage);
    //      referenceCard.LuaScript = referenceCard.LuaScript.replace('[MODEL_SCALE_X]',figData.modelScaleX);
    //      referenceCard.LuaScript = referenceCard.LuaScript.replace('[MODEL_SCALE_Y]',figData.modelScaleY);
    //      referenceCard.LuaScript = referenceCard.LuaScript.replace('[NICKNAME]',figData.name);

    //     factionContainer.ObjectStates[0].ContainedObjects.push(referenceCard);
    // })
    //console.log("missmatchs: " + missmatch)
}