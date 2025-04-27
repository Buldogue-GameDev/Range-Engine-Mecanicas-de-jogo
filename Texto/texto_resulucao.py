import Range  

def main():
    # Obtém o controlador atual
    controlador = Range.logic.getCurrentController()
    
    # O 'owner' do controlador é o objeto ao qual o controlador está ligado
    objeto_fonte = controlador.owner
    
    # Define a resolução do texto (quanto maior o valor, maior a qualidade)
    objeto_fonte.resolution = 1024  # Ajuste o valor conforme necessário
