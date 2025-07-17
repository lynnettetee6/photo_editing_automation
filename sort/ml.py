import moondream as md
from PIL import Image
from pathlib import Path
import rawpy
import logging
import os 
from dotenv import load_dotenv
from sentence_transformers import CrossEncoder


# set up logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# load env vars
load_dotenv()
md_api_key = os.getenv("MOONDREAM_API_KEY")


def is_blurry_moondream(filepath: Path):
    
    logger.debug(f'Evaluating moondream blur of {filepath.name}...')

    try:
        lower_res_ext = ['.jpg', '.jpeg', '.png', '.tiff']

        # skip raf if jpg is available
        media = filepath.parent
        occurence = [i for i in media.iterdir() if i.stem == filepath.stem]
        if filepath.suffix.lower() not in lower_res_ext and len(occurence) > 1 and any([i for i in occurence if i.suffix.lower() == '.jpg']):
            logger.debug(f'{filepath.name} is skipped to save time as a lower resolution exists for processing.')
            return
        

        # read image 
        if filepath.suffix.lower() not in lower_res_ext:
            with rawpy.imread(str(filepath)) as raw:
                filepath_arr = raw.postprocess()
            image = Image.fromarray(filepath_arr)
        else:
            image = Image.open(filepath)
        if image is None: 
            raise Exception

        # Part 1. Moondream image analysis. For Moondream Cloud, use your API key:
        model = md.vl(api_key=md_api_key)

        blur_prompt = '''
        Analyze this image as a professional photo editor. Determine if this image is TOO BLURRY to edit, or if any blur is INTENTIONAL and artistic.

        INTENTIONAL ARTISTIC BLUR (image is GOOD):
        - Bokeh: Sharp subject with beautifully blurred background
        - Light trails: Streaking lights from cars, stars, or movement
        - Motion blur: Deliberate blur showing movement while key elements remain sharp
        - Selective focus: One part sharp, other parts artistically blurred
        - Long exposure: Water, clouds, or lights creating smooth blur effects

        TOO BLURRY (image is BAD):
        - Camera shake: Everything appears unfocused and shaky
        - Out of focus: Main subject lacks sharp edges and definition
        - Motion blur where sharpness was intended
        - No clear focal point or area of sharpness anywhere

        Look for: Are there ANY sharp, well-defined edges in the image? Is there a clear subject or focal point? Does the blur appear deliberate and aesthetically pleasing?

        Answer with either "TOO BLURRY" or "ACCEPTABLE" and explain your reasoning.
        '''

        # logger.debug(f"\n\n-----{subject_desc}-----\n")
        # logger.debug(model.query(image, subject_desc)["answer"])

        # logger.debug(f"\n\n-----{artistic_blur}-----\n")
        # logger.debug(model.query(image, artistic_blur)["answer"])
        
        logger.debug(f"\n\n-----{blur_prompt}-----\n")
        res = model.query(image, blur_prompt)["answer"]
        logger.debug(res)

        # Part 2. sentence analysis. 

        predicate = 'This image is too blurry to edit.'
        
        model = CrossEncoder('cross-encoder/nli-deberta-v3-base')
        
        scores = model.predict([(res, predicate)])

        #Convert scores to labels
        label_mapping = ['contradiction', 'entailment', 'neutral']
        
        labels = [label_mapping[score_max] for score_max in scores.argmax(axis=1)]

        logger.debug(f"NLI Analysis: {labels}")

        # Part 3. post process res
        if 'ACCEPTABLE' in res or 'contradiction' in labels:
            is_blurry = 0
        if 'TOO BLURRY' in res or 'entailment' in labels:
            is_blurry = 1
        else:
            is_blurry = 0

        return is_blurry

    except Exception as e:
        logger.error(f'Unable to process {filepath.name} due to error: {e}') 
        raise e
    
