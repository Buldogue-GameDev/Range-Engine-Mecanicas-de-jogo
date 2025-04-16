import Range

def main():
    # Obtém o controlador atual
    controlador = Range.logic.getCurrentController()
    
    # O 'owner' do controlador é o objeto ao qual o controlador está ligado
    objeto_fonte = controlador.owner
    
    # Define o texto exibido no objeto de fonte
    objeto_fonte.text = "Novo texto exibido"  # Substitua pelo texto desejado
