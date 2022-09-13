const fs = require('fs');
const path = require('path');

const [, , content] = process.argv;

const dest = path.join(__dirname, '__renders__');
fs.writeFileSync(path.join(dest, '1.html'), content);
