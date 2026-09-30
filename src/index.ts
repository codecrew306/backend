import dotenv from 'dotenv';
import { createApp } from './app';

dotenv.config();

const app = createApp();
const port = process.env.PORT || 3000;
const environment = process.env.NODE_ENV || 'development';

app.listen(port, () => {
  console.log(`[server]: ${environment} is running at http://localhost:${port} ......`);
});
