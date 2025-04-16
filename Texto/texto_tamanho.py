import Range

def main():
    # Obtém o controlador atual
    controlador = Range.logic.getCurrentController()
    
    # O 'owner' do controlador é o objeto ao qual o controlador está ligado
    objeto_fonte = controlador.owner
    
    # Define o tamanho do texto (quanto maior o valor, maior o tamanho da fonte)
    objeto_fonte.size = 2  # Ajuste o valor conforme necessário
