import pickle

def pickleLoader(pklFile):
    try:
        while True:
            yield pickle.load(pklFile)
    except EOFError:
        pass
    
def mysql_loader(file, query, cnxA):

    upload_cursor = cnxA.cursor()
    
    i = 0
    f = open(file, "rb")
    for row in pickleLoader(f):
        i += 1
        upload_cursor.execute(query, row)
        if i % 1000 == 0:
            cnxA.commit()
        
    cnxA.commit()
    upload_cursor.close()
    f.close()
    return i
