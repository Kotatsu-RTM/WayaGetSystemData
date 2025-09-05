import 'dotenv/config';
import fastify from 'fastify';
import { spawn } from 'child_process';
import si from 'systeminformation';

const server = fastify({ logger: { level: 'debug' } });

// 環境変数からAPIキーを読み込む
const API_KEY = process.env.WGS_API_KEY;

// 認証ミドルウェア
server.addHook('preHandler', (request, reply, done) => {
  if (!API_KEY) {
    // API_KEYが設定されていない場合は認証をスキップ（開発用など）
    done();
    return;
  }

  const authHeader = request.headers['authorization'];
  if (!authHeader || authHeader !== `Bearer ${API_KEY}`) {
    reply.code(401).send({ message: 'Unauthorized' });
    return;
  }
  done();
});

server.get('/api/fastfetch', (request, reply) => {
  const { modules } = request.query as { modules?: string }; // format を削除

  const promise = new Promise<string>((resolve, reject) => {
    const args = ['--logo', 'none', '--format', 'json']; // --format json を追加
    const fastfetch = spawn('fastfetch', args);
    let result = '';
    let error = '';

    fastfetch.stdout.on('data', (data) => {
      result += data.toString();
    });

    fastfetch.stderr.on('data', (data) => {
      error += data.toString();
    });

    fastfetch.on('close', (code) => {
      if (code === 0) {
        resolve(result);
      } else {
        console.error(`fastfetch exited with code ${code}`);
        console.error(`stderr: ${error}`);
        reject(new Error(`fastfetch exited with code ${code}`));
      }
    });

    fastfetch.on('error', (err) => {
      console.error('Failed to start subprocess.');
      reject(err);
    });
  });

  promise.then(data => {
    let formattedData: string | object;
    let contentType: string;

    // fastfetchの出力をパースする関数
    const parseFastfetchOutput = (output: string, modules?: string) => {
      try {
        const parsedJson = JSON.parse(output);
        if (!Array.isArray(parsedJson)) {
          throw new Error('Fastfetch output is not a JSON array.');
        }

        if (modules === 'list') { // modules=list の場合、モジュールリストを返す
          return parsedJson.filter(item => item.type).map(item => ({ key: item.type, value: item.type }));
        }

        if (modules) {
          const requestedModules = modules.split(',').map(m => m.trim().toLowerCase());
          const filteredItems: { key: string; value: any }[] = [];
          parsedJson.forEach((item: any) => {
            if (item.type && requestedModules.includes(item.type.toLowerCase())) {
              filteredItems.push({ key: item.type, value: item.result || item.error });
            }
          });
          return filteredItems;
        } else {
          // modulesが指定されていない場合は、すべての結果を返す
          const allItems: { key: string; value: any }[] = [];
          parsedJson.forEach((item: any) => {
            if (item.type) {
              allItems.push({ key: item.type, value: item.result || item.error });
            }
          });
          return allItems;
        }
      } catch (e) {
        console.error('Error parsing fastfetch JSON output:', e);
        // JSONパースに失敗した場合は、元のKey:Value形式のパースを試みる
        const lines = output.split('\n');
        const parsedItems: { key: string; value: string }[] = [];
        let foundLocale = false;

        for (const line of lines) {
          if (line.includes('Locale:')) {
            foundLocale = true;
            continue; // Localeの行自体は含めない
          }
          if (foundLocale) {
            continue; // Locale以降の行はスキップ
          }

          if (line.includes(':')) {
            const [key, ...valueParts] = line.split(':');
            const trimmedKey = key.trim();
            if (!modules || modules.split(',').includes(trimmedKey)) {
              parsedItems.push({ key: trimmedKey, value: valueParts.join(':').trim() });
            }
          }
        }
        return [];
      }
    };

    // 常にJSON形式で返す
    reply.header('Content-Type', 'application/json').send(JSON.stringify(parseFastfetchOutput(data, modules)));
  }).catch(err => {
    reply.status(500).send('Internal Server Error');
  });
});

server.get('/api/systeminfo', async (request, reply) => {
  const { modules } = request.query as { modules?: string };
  try {
    if (modules === 'list') { // modules=list の場合、モジュールリストを返す
      const availableModules = Object.keys(si).filter(key => typeof (si as any)[key] === 'function' && !key.startsWith('_'));
      reply.header('Content-Type', 'application/json').send(availableModules);
      return;
    }

    if (modules) {
      const moduleList = modules.split(',');
      const systemInfo: { [key: string]: any } = {};
      for (const module of moduleList) {
        if (typeof (si as any)[module] === 'function') {
          systemInfo[module] = await (si as any)[module]();
        }
      }
      // 物理インターフェースのみをフィルタリング (si.get()で取得した場合も適用)
      if (systemInfo.networkInterfaces) {
        systemInfo.networkInterfaces = (systemInfo.networkInterfaces as any[]).filter((net: any) => !net.internal && !net.virtual && !net.iface.startsWith('br-'));
      }
      reply.header('Content-Type', 'application/json').send(systemInfo);
    } else {
      // 1. 必要なデータをそれぞれ取得する
      const staticData = await si.getStaticData();
      const memData = await si.mem();
      const timeData = await si.time();     // <-- Uptimeのために追加
      const fsSizeData = await si.fsSize(); // <-- Disk Usageのために追加
      
      // 2. staticDataからネットワーク情報を取り出し、フィルターをかける
      const filteredNet = staticData.net.filter(net => 
          !net.internal && !net.virtual && !net.iface.startsWith('br-')
      );
      
      // 3. フィルター後のネットワーク情報を使って最終的なオブジェクトを作成する
      const responseData = {
          ...staticData,      // 元の静的データをすべてコピー
          mem: memData,       // メモリ情報を追加
          time: timeData,     // <-- Uptimeの情報を追加
          fsSize: fsSizeData, // <-- Disk Usageの情報を追加
          net: filteredNet    // ネットワーク情報をフィルター後のものに上書き
      };
      
      // 4. 最終的なデータを返す
      reply.header('Content-Type', 'application/json').send(responseData);
    }
  } catch (e) {
    server.log.error(e);
    reply.status(500).send({ error: 'Failed to get system information' });
  }
});

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;

server.listen({ port: PORT, host: '0.0.0.0' }, (err, address) => {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log(`Server listening at ${address}`);
});
