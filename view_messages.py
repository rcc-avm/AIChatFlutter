#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт для просмотра последних сообщений из базы данных Flutter AI Chat приложения.
"""
import sqlite3
import os
from datetime import datetime

def view_messages():
    # Путь к базе данных Flutter приложения
    flutter_db_path = ".dart_tool/sqflite_common_ffi/databases/chat_cache.db"

    if not os.path.exists(flutter_db_path):
        print(f"База данных не найдена: {flutter_db_path}")
        return

    print(f"Подключаемся к базе данных: {flutter_db_path}")

    try:
        # Подключаемся к базе данных
        conn = sqlite3.connect(flutter_db_path)
        cursor = conn.cursor()

        # Проверяем таблицы
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        print(f"\nНайденные таблицы: {tables}")

        if not tables:
            print("В базе данных нет таблиц.")
            return

        # Показываем последние 10 сообщений из таблицы messages
        print("\n=== ПОСЛЕДНИЕ 10 СООБЩЕНИЙ ===")
        try:
            cursor.execute("""
                SELECT id, is_user, content, timestamp, model_id, tokens, cost
                FROM messages
                ORDER BY timestamp DESC
                LIMIT 10
            """)

            messages = cursor.fetchall()

            if not messages:
                print("Таблица messages пуста.")
            else:
                for msg in reversed(messages):
                    msg_id, is_user, content, timestamp, model_id, tokens, cost = msg

                    user_type = "ПОЛЬЗОВАТЕЛЬ" if is_user == 1 else "AI"
                    print(f"ID: {msg_id} | {user_type}")
                    print(f"Модель: {model_id} | Токены: {tokens} | Стоимость: {cost}")
                    print(f"Время: {timestamp}")
                    if content:
                        content_preview = content[:100] + "..." if len(content) > 100 else content
                        print(f"Сообщение: {content_preview}")
                    else:
                        print("Сообщение: (пустое)")
                    print("-" * 50)

                # Общая статистика
                cursor.execute("SELECT COUNT(*) FROM messages")
                total_count = cursor.fetchone()[0]

                cursor.execute("SELECT COUNT(*) FROM messages WHERE is_user = 1")
                user_count = cursor.fetchone()[0]

                cursor.execute("SELECT COUNT(*) FROM messages WHERE is_user = 0")
                ai_count = cursor.fetchone()[0]

                print(f"\nВсего сообщений в базе: {total_count}")
                print(f"Из них пользователь спросил: {user_count}")
                print(f"AI ответило: {ai_count}")

        except sqlite3.OperationalError as e:
            print(f"Ошибка при чтении таблицы messages: {e}")
            print("Возможно, таблицы messages не существует.")

        # Проверяем таблицу auth
        print("\n=== ДАННЫЕ АУТЕНТИФИКАЦИИ ===")
        try:
            cursor.execute("""
                SELECT id, api_key, provider, balance, created_at, updated_at
                FROM auth
                ORDER BY created_at DESC
                LIMIT 5
            """)

            auths = cursor.fetchall()

            if not auths:
                print("Таблица auth пуста.")
            else:
                for auth in auths:
                    auth_id, api_key, provider, balance, created_at, updated_at = auth
                    print(f"ID: {auth_id} | Провайдер: {provider} | Баланс: {balance}")
                    print(f"Ключ: {api_key[:20]}..." if api_key else "Ключ: (отсутствует)")
                    print(f"Создан: {created_at}")
                    print("-" * 30)

        except sqlite3.OperationalError as e:
            print(f"Ошибка при чтении таблицы auth: {e}")
            print("Возможно, таблицы auth не существует.")

        conn.close()

    except Exception as e:
        print(f"Ошибка при работе с базой данных: {e}")

if __name__ == "__main__":
    view_messages()
