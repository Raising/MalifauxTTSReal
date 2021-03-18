

exports.default = function () {


// setTimeout(()=> {
//   screenshot({ filename: 'shot.png',format: 'png' }).then((imgPath) => {
//     processScanImage(imgPath);
//   });
   
// },1000)
    return processScanImage('shot.png');
};

