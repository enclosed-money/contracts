const fs = require('fs');
const path = require('path');

const [, , content] = process.argv;

const dest = path.join(__dirname, '__renders__');

const encodedStuff = content.split(',');
const buff = Buffer.from(encodedStuff[1], 'base64');
const parsed = JSON.parse(buff.toString());
const svgBuff = Buffer.from(parsed.image.split(',')[1], 'base64');

let currentContent;

if (parsed.name.split(' ')[1] === 'ETHER') {

  currentContent = fs.readFileSync(path.join(dest, 'ether.html'));

  if (currentContent.equals(Buffer.from(svgBuff.toString()))) {
    return;
  }

  fs.writeFileSync(path.join(dest, 'ether.html'), svgBuff.toString());
  
} else {

  currentContent = fs.readFileSync(path.join(dest, 'erc20.html'));
  
  if (currentContent.equals(Buffer.from(svgBuff.toString()))) {
    return;
  }

  fs.writeFileSync(path.join(dest, 'erc20.html'), svgBuff.toString());
}