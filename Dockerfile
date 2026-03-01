FROM rubylang/ruby:4.0

WORKDIR /app
COPY chatgpt2obsidian /app/
RUN chmod +x chatgpt2obsidian

ENTRYPOINT ["./chatgpt2obsidian"]
