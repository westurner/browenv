

def response(context, flow):
    flow.response.headers['X-Frame-Options'] = [""]
    #flow.response.headers["X-Frame-Options"] = [""]
    flow.response.headers['mtmprx'] = ['1']
