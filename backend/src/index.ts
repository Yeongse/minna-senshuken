import { Hono } from 'hono';
import { logger } from 'hono/logger';
import { cors } from 'hono/cors';
import { errorHandler } from './middleware/error-handler';
import { championshipsRoutes } from './routes/championships';
import { usersRoutes } from './routes/users';
import { answersRoutes } from './routes/answers';
import { interactionsRoutes } from './routes/interactions';

const app = new Hono();

// Middleware
app.use('*', logger());
app.use('*', cors());

// Global error handler
app.onError(errorHandler);

// Health check endpoint
app.get('/health', (c) => {
  return c.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Root endpoint
app.get('/', (c) => {
  return c.json({ message: 'みんなの選手権 API' });
});

// Routes
app.route('/championships', championshipsRoutes);
app.route('/users', usersRoutes);
app.route('/', answersRoutes);
app.route('/', interactionsRoutes);

const port = parseInt(process.env.PORT ?? '8080', 10);

console.log(`Server starting on port ${port}`);

export default {
  port,
  fetch: app.fetch,
};

export { app };
