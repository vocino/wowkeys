import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..');

export const KEYBINDS_PATH = path.join(REPO_ROOT, 'src/data/keybinds.yml');
export const CACHE_PATH = path.join(REPO_ROOT, 'src/data/abilities_cache.yml');
export const TOKEN_PATH = path.join(REPO_ROOT, 'src/data/.blizzard_token');
export const ENV_PATH = path.join(REPO_ROOT, '.env');
