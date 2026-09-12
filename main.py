import pygame

from utils import resource_path

from game import Game
from end_game import EndGame
from loading_screen import LoadingScreen
from main_menu import MainMenu


pygame.init()

WIDTH = 800
HEIGHT = 600

screen = pygame.display.set_mode(
    (WIDTH, HEIGHT)
)

pygame.display.set_caption(
    "Frog Hunt!"
)

clock = pygame.time.Clock()

pygame.mixer.music.load(
    resource_path("assets/sounds/game_music.mp3")
)

pygame.mixer.music.set_volume(0.5)


main_menu = MainMenu(
    WIDTH,
    HEIGHT
)

loading_screen = None
game = None
end_game = None

current_screen = "main_menu"

running = True

while running:

    for event in pygame.event.get():

        if event.type == pygame.QUIT:

            running = False

        elif current_screen == "main_menu":

            result = main_menu.handle_event(event)

            if result == "play":

                loading_screen = LoadingScreen(
                    WIDTH,
                    HEIGHT
                )

                current_screen = "loading"

            elif result == "quit":

                running = False

        elif current_screen == "game":

            game.handle_event(event)

        elif current_screen == "end_game":

            result = end_game.handle_event(event)

            if result == "game":

                game = Game(
                    WIDTH,
                    HEIGHT
                )

                pygame.mixer.music.play(-1)

                end_game = None
                current_screen = "game"

            elif result == "menu":

                end_game = None
                current_screen = "main_menu"

            elif result == "quit":

                running = False

    if current_screen == "main_menu":

        main_menu.update(clock)
        main_menu.draw(screen)

    elif current_screen == "loading":

        loading_finished = loading_screen.update(
            clock
        )

        loading_screen.draw(screen)

        if loading_finished:

            game = Game(
                WIDTH,
                HEIGHT
            )

            pygame.mixer.music.play(-1)

            current_screen = "game"

    elif current_screen == "game":

        game.update(clock)

        if game.is_finished():

            pygame.mixer.music.stop()

            end_game = EndGame(
                WIDTH,
                HEIGHT,
                game.frogs_caught,
                game.game_time
            )

            current_screen = "end_game"

        else:

            game.draw(screen)

    elif current_screen == "end_game":

        end_game.update(clock)
        end_game.draw(screen)

    pygame.display.flip()

    clock.tick(60)

pygame.quit()