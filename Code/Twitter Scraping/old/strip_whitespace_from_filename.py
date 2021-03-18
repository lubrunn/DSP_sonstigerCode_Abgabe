import os
lang = "de"
os.chdir(rf"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw\Companies_{lang}\Procter Gamble_{lang}")


files = os.listdir()


new_names = [" ".join(file.split()) for file in files]

for i,file in enumerate(files):
    os.rename(file, new_names[i])



