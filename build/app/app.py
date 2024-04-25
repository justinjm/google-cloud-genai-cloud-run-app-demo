from google.cloud import logging

import vertexai

from vertexai.preview.generative_models import GenerativeModel, Part
import vertexai.preview.generative_models as generative_models

import gradio as gr

import config

client = logging.Client(project=config.PROJECT_ID)
client.setup_logging()

logger = client.logger(config.LOG_NAME)

vertexai.init(project=config.PROJECT_ID, location=config.REGION)
model = GenerativeModel(config.MODEL_ID)

def predict(prompt, max_output_tokens, temperature):
    logger.log_text(prompt)
    response = model.generate_content(
        contents = prompt,
        generation_config={
            "max_output_tokens": max_output_tokens,
            "temperature": temperature
        },
        safety_settings={
          generative_models.HarmCategory.HARM_CATEGORY_HATE_SPEECH: generative_models.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          generative_models.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: generative_models.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          generative_models.HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: generative_models.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          generative_models.HarmCategory.HARM_CATEGORY_HARASSMENT: generative_models.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    },
        stream=False)

    return response.text


examples = [
    ["What are some generative AI services on Google Cloud in Public Preview?"],
    ["What is the capital of United States?"],
    ["Suggest a recipe for chocolate chip cookies?"],
]

# Title and Text Section
title_md = """
## Google Cloud Generative AI Demo App

This demo showcases how to interact with Gemini on Google CLoud. For more information, see the [official documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview). 
"""

with gr.Blocks() as demo:
    gr.Markdown(title_md)

    with gr.Row():
        # Input and Output within a single column on the left
        with gr.Column(scale=2):
            prompt = gr.Textbox(label="Enter prompt:",
                                value="What are some generative AI services on Google Cloud in Public Preview?",
                                lines=20)
            output = gr.Textbox(label="Output", 
                                interactive=False,
                                lines=20) 
        
        # Input controls on the right
        with gr.Column(scale=1):
            examples = gr.Examples(examples=examples,
                                   inputs=prompt,
                                   outputs=output,
                                   label="Examples")
            max_output_tokens = gr.Slider(50, 8192, value=8192, step=32, label="max_output_tokens")
            temperature = gr.Slider(0, 2, value=1, step=0.1, label="temperature")
            btn = gr.Button("Generate")
            

    btn.click(predict, inputs=[prompt, max_output_tokens, temperature], outputs=output)

demo.launch(server_name="0.0.0.0", server_port=8080)