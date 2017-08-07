import json

# return None if no data in resultList
def get(inJson, colDict):
    resultList = []
    for i in colDict:
        colHierarchy = i.split('.')
        value = inJson
        for x in colHierarchy:
            if x in value:
                value = value[x]
            else:
                value = ''
            if value == None:
                value = ''
            # print(x)
            # print(value)
        resultList.append(value)
    result_test = [var for var in resultList if var != '']
    if result_test:
        return resultList
    else:
        return None    

# return empty string if no data found for corresponding key
def get_as_default(inJson, colDict):
    resultList = []
    for i in colDict:
        colHierarchy = i.split('.')
        value = inJson
        for x in colHierarchy:
            if x in value:
                value = value[x]
            else:
                value = ''
        resultList.append(value)
    return resultList
