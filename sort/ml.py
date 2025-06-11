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

        # 1. Image Captioning

        # logger.debug("1i. Short caption:")
        # logger.debug(model.caption(image, length="short")["caption"])

        # logger.debug("1. Short caption:")
        # res = model.caption(image, length="short", stream=True)["caption"]
        # logger.debug(''.join(list(res)))
    
        # # 2. Visual Question Answering
        # subject_desc = "Briefly describe the subject, and its cardinal position in the image"

        # artistic_blur = "Does the image have artisitc blur? Examples of 'artistic blurring' are not limited to: bokeh (background blurring), double exposure (two photos overlaying each other), or long exposure (deliberately introducing blurring to the subject as part of a story-telling mechanism)."

        blur_prompt = "From the perspective of a world-renowned photo editor of Gjon Mili with a keen eye, do you think this image is too blurry to be edited? If the subject is out of focus, then the image is too blurry. If the subject has sharp edges, then the image is not blurry. And, why would you say so?"

        # "And, if it is too blurry to be edited, end your reply with '1'; if not, '0'."
        # "Answer '1' if blurry, '0' if not, while meeting both of the following conditions. Condition 1: Examples of 'artistic blurring' are not limited to: bokeh (backgrounxd blurring), double exposure (two photos overlaying each other), or long exposure (deliberately introducing blurring to the subject to indicate motion or chaos). The image is NOT blurry if only 'artistic blurring' is present.  Condition 2: Unless 'artistically blurred', the image is NOT blurry if the subject or area of focus is sharp, i.e. it has distinct, clean, sharp edges. If it is blurry, also reply with '1', or not, '0'."

        # logger.debug(f"\n\n-----{subject_desc}-----\n")
        # logger.debug(model.query(image, subject_desc)["answer"])

        # logger.debug(f"\n\n-----{artistic_blur}-----\n")
        # logger.debug(model.query(image, artistic_blur)["answer"])
        
        logger.debug(f"\n\n-----{blur_prompt}-----\n")
        res = model.query(image, blur_prompt)["answer"]
        logger.debug(res)

        # Part 2. sentence analysis. 

        predicate = 'This image is too blurry.'
        
        model = CrossEncoder('cross-encoder/nli-deberta-v3-base')
        
        scores = model.predict([(res, predicate)])

        #Convert scores to labels
        label_mapping = ['contradiction', 'entailment', 'neutral']
        
        labels = [label_mapping[score_max] for score_max in scores.argmax(axis=1)]

        logger.debug(labels)


        # Part 3. post process res
        if 'entailment' in labels:
            is_blurry = 1
        else: 
            is_blurry = 0


        # 3. Object Detection

        # logger.debug("3. Detecting objects:")
        # objects = model.detect(image, "face")["objects"]
        # logger.debug(f"Found {len(objects)} face(s)")
        # objects = model.detect(image, "eye")["objects"]
        # logger.debug(f"Found {len(objects)} eye(s)")
        ## objects = model.detect(image, "pet")["objects"]
        ## logger.debug(f"Found {len(objects)} pet(s)")

        # 4. Visual Pointing

        # logger.debug("4. Locating objects:")
        # points = model.point(image, "person")["points"]
        # logger.debug(f"Found {len(points)} person(s)")
        return is_blurry

    except Exception as e:
        logger.error(f'Unable to process {filepath.name} due to error: {e}') 
        raise e
    
