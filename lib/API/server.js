const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const userRoutes = require('./routes/user.routes.js');
const messageRoutes = require('./routes/message.routes.js');

const ressourceRoutes = require('./routes/ressource.routes.js');
const activityRoutes = require('./routes/activity.routes.js');
const User = require('./models/user.model.js');

dotenv.config();

const app = express();
const port = process.env.PORT || 5000;

// Middleware de base
app.use(cors());
app.use(express.json());

// 🔤 Forcer l'encodage UTF-8 pour toutes les réponses
app.use((req, res, next) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  next();
});

// Connexion à MongoDB
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('✅ Connexion à MongoDB réussie'))
  .catch((err) => console.error('❌ Erreur de connexion à MongoDB :', err));

// 🔗 Routes API
app.use('/api', userRoutes);
app.use('/api', activityRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/ressources', ressourceRoutes);


// 🚀 Lancement du serveur
app.listen(port, '0.0.0.0', () => {
  console.log(`✅ Serveur en écoute sur http://0.0.0.0:${port}`);
});
