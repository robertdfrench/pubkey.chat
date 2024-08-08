import curses
import time
import threading
import uuid

API_BASE_URL = "http://example.com"  # Replace with the actual base URL of the web service
MESSAGE_LIST = []

def fetch_messages():
    MESSAGE_LIST.append(str(uuid.uuid4()))
    return MESSAGE_LIST

def post_message(message):
    MESSAGE_LIST.append(message)

def chat_window(stdscr):
    curses.curs_set(0)  # Hide cursor
    stdscr.nodelay(1)  # Don't block when waiting for input
    stdscr.timeout(1000)  # Refresh every second

    messages_win = curses.newwin(curses.LINES - 3, curses.COLS, 0, 0)
    input_win = curses.newwin(3, curses.COLS, curses.LINES - 3, 0)
    
    input_win.addstr(1, 1, "> ")
    input_win.refresh()
    
    current_input = ""
    messages = []

    def update_messages():
        nonlocal messages
        while True:
            new_messages = fetch_messages()
            if new_messages:
                messages = new_messages
            time.sleep(2)

    # Start a background thread to update messages
    thread = threading.Thread(target=update_messages)
    thread.daemon = True
    thread.start()

    while True:
        messages_win.clear()
        input_win.clear()
        input_win.addstr(1, 1, f"> {current_input}")

        for i, msg in enumerate(messages[-(curses.LINES - 3):]):
            messages_win.addstr(i, 0, msg)

        messages_win.refresh()
        input_win.refresh()

        key = stdscr.getch()
        if key == curses.KEY_RESIZE:
            # Resize windows if terminal size changes
            messages_win.resize(curses.LINES - 3, curses.COLS)
            input_win.resize(3, curses.COLS)
            input_win.mvwin(curses.LINES - 3, 0)
        elif key == ord('\n'):
            if current_input.strip():
                post_message(current_input.strip())
                current_input = ""
        elif key == 27:  # Escape key
            break
        elif key == curses.KEY_BACKSPACE or key == 127:
            current_input = current_input[:-1]
        elif key != -1:
            current_input += chr(key)

curses.wrapper(chat_window)
