import logging
import os 
from dotenv import load_dotenv
from datetime import datetime
from pathlib import Path

load_dotenv()

root_dir = os.getenv("ROOT_DIR")
log_path = os.getenv('LOG_PATH')

## Configure root logger
root_logger = logging.getLogger()
formatter = logging.Formatter('[%(asctime)s.%(msecs)03d] %(levelname)s [%(name)s]: %(message)s', 
                              datefmt='%Y-%m-%d %H:%M:%S')

stream_handler = logging.StreamHandler()
stream_handler.setLevel(logging.DEBUG)
stream_handler.setFormatter(formatter)

# Create log file
now = datetime.now().strftime("%Y-%m-%d_%H-%M-%S-%f")[:-3]  # strip last 3 digits for ms precision
full_log_path = Path(root_dir) / Path(log_path) / now
full_log_path.touch(exist_ok=True)

file_handler = logging.FileHandler(f'{full_log_path}.log') # TODO backspace if windows, other systems
file_handler.setLevel(logging.DEBUG)
file_handler.setFormatter(formatter)

root_logger.addHandler(stream_handler)
root_logger.addHandler(file_handler)

root_logger.propagate=True