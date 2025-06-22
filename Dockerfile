FROM rubylang/ruby:3.4

WORKDIR /app
COPY chatgpt2obsidian /app/
RUN chmod +x chatgpt2obsidian

ENTRYPOINT ["./chatgpt2obsidian"]
