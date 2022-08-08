const { Address, Account, BN } = require('ethereumjs-util');
const { defaultAbiCoder, Interface } = require('@ethersproject/abi');
const { DOMParser } = require('xmldom');
const { Transaction } = require('@ethereumjs/tx');
const EventEmitter = require('events');
const fs = require('fs');
const http = require('http');
const os = require('os');
const path = require('path');
const solc = require('solc');
const VM = require('@ethereumjs/vm').default;

const SOURCE = path.join(__dirname, 'src', 'BillExample.sol');

async function boot() {
  const pk = Buffer.from(
    '1122334455667788112233445566778811223344556677881122334455667788',
    'hex'
  );

  const accountAddress = Address.fromPrivateKey(pk);
  const account = Account.fromAccountData({
    nonce: 0,
    balance: new BN(10).pow(new BN(18 + 2)), // 100 eth
  });

  const vm = new VM();
  await vm.stateManager.putAccount(accountAddress, account);

  return { vm, pk };
}

async function call(vm, address, abi, name, args = []) {
  const iface = new Interface(abi);
  const data = iface.encodeFunctionData(name, args);

  const renderResult = await vm.runCall({
    to: address,
    caller: address,
    origin: address,
    data: Buffer.from(data.slice(2), 'hex'),
  });

  if (renderResult.execResult.exceptionError) {
    throw renderResult.execResult.exceptionError;
  }

  const logs = renderResult.execResult.logs?.map(([address, topic, data]) =>
    data.toString().replace(/\x00/g, '')
  );

  if (logs?.length) {
    console.log(logs);
  }

  const results = defaultAbiCoder.decode(
    ['string'],
    renderResult.execResult.returnValue
  );

  return results[0];
}

function getSolcInput(source) {
  return {
    language: 'Solidity',
    sources: {
      [path.basename(source)]: {
        content: fs.readFileSync(source, 'utf8'),
      },
    },
    settings: {
      optimizer: {
        enabled: false,
        runs: 1,
      },
      evmVersion: 'london',
      outputSelection: {
        '*': {
          '*': ['abi', 'evm.bytecode'],
        },
      },
    },
  };
}

function findImports(src) {
  try {
    const remappings = fs
      .readFileSync(path.join(__dirname, 'remappings.txt'), 'utf8')
      .split('\n')
      .filter(Boolean)
      .map((s) => s.split('='));
    src = remappings.reduce((acc, pair) => acc.replace(pair[0], pair[1]), src);
    const file = fs.existsSync(path.join(__dirname, src))
      ? fs.readFileSync(path.join(__dirname, src), 'utf8')
      : fs.existsSync(src)
      ? fs.readFileSync(src, 'utf8')
      : fs.readFileSync(require.resolve(src), 'utf8');
    return { contents: file };
  } catch (error) {
    console.error(error);
    return { error };
  }
}

function compile(source) {
  const input = getSolcInput(source);
  process.chdir(path.dirname(source));
  const output = JSON.parse(
    solc.compile(JSON.stringify(input), { import: findImports })
  );

  let errors = [];

  if (output.errors) {
    for (const error of output.errors) {
      if (error.severity === 'error') {
        errors.push(error.formattedMessage);
      }
    }
  }

  if (errors.length > 0) {
    throw new Error(errors.join('\n\n'));
  }

  const result = output.contracts[path.basename(source)];
  const contractName = Object.keys(result)[0];
  return {
    abi: result[contractName].abi,
    bytecode: result[contractName].evm.bytecode.object,
  };
}

async function deploy(vm, pk, bytecode) {
  const address = Address.fromPrivateKey(pk);
  const account = await vm.stateManager.getAccount(address);

  const txData = {
    value: 0,
    gasLimit: 200_000_000_000,
    gasPrice: 1,
    data: '0x' + bytecode.toString('hex'),
    nonce: account.nonce,
  };

  const tx = Transaction.fromTxData(txData).sign(pk);

  const deploymentResult = await vm.runTx({ tx });

  if (deploymentResult.execResult.exceptionError) {
    throw deploymentResult.execResult.exceptionError;
  }

  return deploymentResult.createdAddress;
}

async function serve(handler) {
  const events = new EventEmitter();

  function requestListener(req, res) {
    if (req.url === '/changes') {
      res.setHeader('Content-Type', 'text/event-stream');
      res.writeHead(200);
      const sendEvent = () => res.write('event: change\ndata:\n\n');
      events.on('change', sendEvent);
      req.on('close', () => events.off('change', sendEvent));
      return;
    }

    if (req.url === '/') {
      res.writeHead(200);
      handler().then(
        (content) => res.end(webpage(content)),
        (error) => res.end(webpage(`<pre>${error.message}</pre>`))
      );
      return;
    }

    res.writeHead(404);
    res.end('Not found: ' + req.url);
  }
  const server = http.createServer(requestListener);
  await new Promise((resolve) => server.listen(9901, resolve));

  return {
    notify: () => events.emit('change'),
  };
}

const webpage = (content) => `
<html>
<title>Hot Chain SVG</title>
${content}
<script>
const sse = new EventSource('/changes');
sse.addEventListener('change', () => window.location.reload());
</script>
</html>
`;

async function server() {
  const { vm, pk } = await boot();

  async function handler() {
    const { abi, bytecode } = compile(SOURCE);
    const address = await deploy(vm, pk, bytecode);
    const result = await call(vm, address, abi, 'example');
    return result;
  }

  const { notify } = await serve(handler);

  fs.watch(path.dirname(SOURCE), notify);
  console.log('Watching', path.dirname(SOURCE));
  console.log('Serving  http://localhost:9901/');
}

async function qa() {
  const DESTINATION = path.join(os.tmpdir(), 'hot-chain-svg-');

  const { vm, pk } = await boot();
  const { abi, bytecode } = compile(SOURCE);
  const address = await deploy(vm, pk, bytecode);

  const tempFolder = fs.mkdtempSync(DESTINATION);
  console.log('Saving to', tempFolder);

  const samples = [
    ['Watchfaces', '0x8d3b078d9d9697a8624d4b32743b02d270334af1', 0],
    [
      'Nation3 "Genesis" Passport',
      '0x3337dac9f251d4e403d6030e18e3cfb6a2cb1333',
      1,
    ],
    ['Blockheads', '0x3337dac9f251d4e403d6030e18e3cfb6a2cb1333', 2],
    ['', '0x3337dac9f251d4e403d6030e18e3cfb6a2cb1333', 3],
    ['Dinos', '0x3337dac9f251d4e403d6030e18e3cfb6a2cb1333', 4],
  ];

  for (let i = 0; i < samples.length; i++) {
    const fileName = path.join(tempFolder, i + '.svg');
    console.log('Rendering', fileName);
    const svg = await call(vm, address, abi, 'render', [...samples[i]]);
    fs.writeFileSync(fileName, svg);

    // Throws on invalid XML
    new DOMParser().parseFromString(svg);
  }
}

async function main() {
  if (process.argv[2] === 'qa') {
    return qa();
  }

  return server();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
