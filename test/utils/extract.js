const fs = require('fs');
const path = require('path');

const [, , content] = process.argv;

const dest = path.join(__dirname, '__renders__');

const currentContent = fs.readFileSync(path.join(dest, '1.html'));

if (currentContent.equals(Buffer.from(content))) {
 return;
} 

fs.writeFileSync(path.join(dest, '1.html'), content);
