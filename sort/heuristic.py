from pathlib import Path
import cv2
import numpy as np
import rawpy
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

def is_blurry_laplacian(filepath: Path, pass_threshold=10.0):
    try: 
        logger.debug(f'Evaluating Laplacian blur of {filepath.name}...')

        # # set pass/fail threshold
        suffix = filepath.suffix.lower()
        # if suffix in ['.jpg', '.jpeg']:
        #     pass_threshold = pass_threshold_high
        # else: # RAF, CR3, etc high def files
        #     pass_threshold = pass_threshold_high
        
        # read image 
        if suffix not in ['.jpg', '.jpeg', '.png', '.tiff']:
            with rawpy.imread(str(filepath)) as raw:
                filepath_arr = raw.postprocess()
        else:
            filepath_arr = cv2.imread(str(filepath))
        if filepath_arr is None: 
            raise Exception

        # evaluate
        gray = cv2.cvtColor(filepath_arr, cv2.COLOR_BGR2GRAY)
        laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
        logger.debug(f'\nLaplacian variance of {filepath.name} :{laplacian_var}')
        
        return laplacian_var < pass_threshold
    
    except Exception as e:
        logger.error(f'Unable to process {filepath.name} due to error: {e}') 
        raise e


def is_bad_exposure(filepath: Path, dark_thresh=30, bright_thresh=225, pass_threshold_low=0.7, pass_threshold_high=0.9):
    try: 
        logger.debug(f'Evaluating exposure of {filepath.name}...')

        # set pass/fail threshold
        suffix = filepath.suffix.lower()
        if suffix in ['.jpg', '.jpeg']:
            pass_threshold = pass_threshold_low
        else: # RAF, CR3, etc high def files
            pass_threshold = pass_threshold_high
        
        # read image 
        if suffix not in ['.jpg', '.jpeg', '.png', '.tiff']:
            with rawpy.imread(str(filepath)) as raw:
                filepath_arr = raw.postprocess()
        else:
            filepath_arr = cv2.imread(str(filepath))
        if filepath_arr is None: 
            raise Exception

        # evaluate
        gray = cv2.cvtColor(filepath_arr, cv2.COLOR_BGR2GRAY)
        hist = cv2.calcHist([gray], [0], None, [256], [0, 256])
        total = gray.size
        under = np.sum(hist[:dark_thresh]) / total
        over = np.sum(hist[bright_thresh:]) / total
        logger.debug(f'\n% darker than {dark_thresh}: {str(round(under*100,1))}%\n% brighter than {bright_thresh}: {str(round(over*100,1))}%')
        if under > pass_threshold or over > pass_threshold:
            logger.debug(f'{filepath.name} is overly under/overexposed.')
        return under > pass_threshold or over > pass_threshold 
    
    except Exception as e:
        logger.error(f'Unable to process {filepath.name} due to error: {e}') 
        raise e
