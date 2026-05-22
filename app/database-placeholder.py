import os
import socket

HOST = "0.0.0.0"
PORT = int(os.getenv("DATABASE_PORT", "5432"))

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen()

    while True:
        connection, _ = server.accept()
        with connection:
            connection.sendall(b"database placeholder\n")
