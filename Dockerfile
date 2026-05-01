FROM node:20.1.0-alpine AS builder
WORKDIR /app
COPY package.json .
COPY *.js .
RUN npm install

FROM node:20.1.0-alpine 
WORKDIR /app
EXPOSE 8080
COPY --from=builder /app /app
RUN addgroup -S roboshop && adduser -S roboshop -G roboshop
RUN chown -R roboshop:roboshop /app
USER roboshop
CMD ["server.js"]
ENTRYPOINT [ "node" ]


# FROM node:20
# WORKDIR /app
# COPY package.json .
# COPY *.js .
# RUN npm install
# # ENV MONGO=true \
# #     MONGO_URL="mongodb://mongodb:27017/catalogue"
# CMD ["node", "server.js"]
