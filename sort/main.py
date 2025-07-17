import heuristic as heu
import ml

import os 
from dotenv import load_dotenv
from datetime import datetime

from pathlib import Path
import typing as T
import shutil
import logger_config


# set up logger
logger = logger_config.logging.getLogger(__name__)
logger.setLevel(logger_config.logging.DEBUG)

# load env vars
load_dotenv()

root_dir = os.getenv("ROOT_DIR")
media_path_ = os.getenv("MEDIA_PATH")
edit = os.getenv("EDIT_PATHANME") if os.getenv("EDIT_PATHANME") else "edit"
rm = os.getenv("RM_PATHANME") if os.getenv("RM_PATHANME") else "rm"
metric = os.getenv("METRIC")
attribute = os.getenv("ATTRIBUTE")
subattribute = os.getenv("SUBATTRIBUTE")
processed_log_name = os.getenv("PROCESSED_LOG_NAME")


def main():
    # define my images
    media_path = Path(fr'{str(media_path_)}')
    media = media_path / metric / attribute / subattribute
    logger.debug(f'\n---------ROOT_PATH---------: {root_dir}\n---------MEDIA_PATH---------: {media_path_}\n---------METRIC---------: {metric}\n---------ATTRIBUTE---------: {attribute}\n---------SUBATTRIBUTE---------: {subattribute}\n')

    # define and create save paths
    processed_log = media_path / processed_log_name
    processed_log.touch(exist_ok=True)

    rm_path = media / f'{media_path.name}_{rm}' # define
    rm_path.mkdir(parents=True, exist_ok=True) # create
    edit_path = media / f'{media_path.name}_{edit}'
    edit_path.mkdir(parents=True, exist_ok=True)

    images = [f for f in media.iterdir() if f.is_file() and not any(ext.lower() in f.name.lower() for ext in ['.DS_Store', '.mov', '.mp4', '.avi', '.txt', '.log'])]

    # skip images that have been processed 
    with open(processed_log, 'r') as f:
        processed_images = set(line.strip() for line in f)
    images = [f for f in images if f.name not in processed_images]

    # sort by images by file size ascending
    images = sorted(images, key=lambda f: f.stat().st_size, reverse=False)

    # sort images to bins based on test metric
    time_per_img = []
    for image in images:
        try:
            start_time = datetime.now().timestamp()
            if heu.is_bad_exposure(image) or ml.is_blurry_moondream(image):
            # TODO to save time - if is blurry, move both jpg and raf to rm path. If bad exposure, move jpg but not raf
                shutil.move(image, rm_path) # mv to rm path
                logger.debug(f'moving {image.name} to {rm_path.name}')
            else: 
                shutil.move(image, edit_path) # mv to edit path
                logger.debug(f'moving {image.name} to {edit_path.name}')
            end_time = datetime.now().timestamp()
            time_taken = end_time - start_time
            
            logger.debug(f'Time taken: {time_taken}')
            time_per_img.append(time_taken)
            
            # log the processed image
            logger.debug(f"Recording image as processed...")
            with open(processed_log, 'a') as f:
                f.write(f'{image.name}\n')
            
        except Exception as e:
            logger.error(f"Error occured at evaluation: {e}")
    
    avg_time_per_img = sum(time_per_img)/(len(time_per_img) + 0.001)

    logger.debug(f'\n\n---------AVG TIME PER IMAGE---------: {avg_time_per_img}')
        
if __name__ == "__main__": 
    main()
