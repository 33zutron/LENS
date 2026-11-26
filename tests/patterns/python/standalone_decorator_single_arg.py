#ERROR:
@art("deco")
class room():
  #OK:
  def desk():
    return None

#OK
@empty_deco
#ERROR:
@arg_deco("lens")
def decorate():
  return "flowers!"
