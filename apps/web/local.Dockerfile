FROM node:25-bullseye

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Default port, can be overridden by environment variable
ARG PORT=3000
ENV PORT=${PORT}

EXPOSE ${PORT}

CMD ["npm", "run", "dev"]
