import json
import urllib.parse
import boto3
import os
from PIL import Image

# Initialisation du client S3
s3 = boto3.client('s3')

def lambda_handler(event, context):
    try:
        # 1. Récupérer le nom du bucket source et le nom du fichier (key) depuis l'événement S3
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        file_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
        
        # 2. Déduire le nom du bucket de destination 
        # (Grâce à notre Terraform, on sait qu'il suffit de remplacer '-source-' par '-dest-')
        dest_bucket = source_bucket.replace('-source-', '-dest-')
        
        # Chemins temporaires dans l'environnement Lambda (limité à /tmp/)
        download_path = f"/tmp/{os.path.basename(file_key)}"
        
        # 3. Télécharger l'image depuis le bucket source
        print(f"Téléchargement de {file_key} depuis {source_bucket}...")
        s3.download_file(source_bucket, file_key, download_path)
        
        # 4. Renommer le fichier (préparer le nouveau nom avec l'extension .pdf)
        base_name = os.path.splitext(os.path.basename(file_key))[0]
        new_file_name = f"{base_name}_converti.pdf"
        upload_path = f"/tmp/{new_file_name}"
        
        # 5. Convertir l'image en PDF avec la librairie Pillow
        print("Conversion de l'image en PDF...")
        image = Image.open(download_path)
        
        # Si l'image a de la transparence (comme un PNG), on la convertit en RGB
        if image.mode in ("RGBA", "P"):
            image = image.convert("RGB")
            
        image.save(upload_path, "PDF", resolution=100.0)
        
        # 6. Uploader le PDF final dans le bucket de destination
        print(f"Upload du PDF {new_file_name} vers {dest_bucket}...")
        s3.upload_file(upload_path, dest_bucket, new_file_name)
        
        return {
            'statusCode': 200,
            'body': json.dumps(f'Succès : {file_key} converti en {new_file_name}')
        }
        
    except Exception as e:
        print(f"Erreur lors du traitement : {e}")
        raise e