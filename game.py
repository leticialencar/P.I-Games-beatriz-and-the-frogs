import pygame
import random

from utils import resource_path

from player import Player
from frog import Frog


class Game:

    def __init__(self, width, height):

        self.width = width
        self.height = height

        self.background = pygame.image.load(
            resource_path("assets/background/background.png")
        ).convert()

        self.background = pygame.transform.scale(
            self.background,
            (self.width, self.height)
        )

        self.font = pygame.font.Font(
            resource_path("assets/fonts/Minecraftia-Regular.ttf"),
            12
        )

        self.frog_icon = pygame.image.load(
            resource_path("assets/frog/frog_icon.png")
        ).convert_alpha()

        self.frog_icon = pygame.transform.scale(
            self.frog_icon,
            (46, 46)
        )

        self.counter_background = pygame.image.load(
            resource_path("assets/ui/frog_counter_bg.png")
        ).convert_alpha()

        self.counter_background = pygame.transform.scale(
            self.counter_background,
            (140, 80)
        )

        self.player = Player(
            100,
            100,
            self.width,
            self.height
        )

        self.frogs = [
            Frog(150, 180),
            Frog(350, 250),
            Frog(550, 180),
            Frog(250, 450),
            Frog(650, 450)
        ]

        self.frogs_caught = 0

        self.min_frogs = 3
        self.max_frogs = 8

        self.spawn_timer = 0
        self.spawn_interval = random.randint(300, 700)

        self.game_time = 0
        self.game_duration = 60000

    def handle_event(self, event):

        if event.type == pygame.KEYDOWN:

            if event.key == pygame.K_e:

                for frog in self.frogs:

                    distance_x = abs(
                        self.player.x - frog.x
                    )

                    distance_y = abs(
                        self.player.y - frog.y
                    )

                    if distance_x < 80 and distance_y < 80:

                        self.frogs.remove(frog)
                        self.frogs_caught += 1

                        self.spawn_timer = 0
                        self.spawn_interval = random.randint(
                            300,
                            700
                        )

                        break

    def create_frog(self):

        for _ in range(100):

            x = random.randint(
                50,
                self.width - 100
            )

            y = random.randint(
                50,
                self.height - 120
            )

            distance_x = abs(
                self.player.x - x
            )

            distance_y = abs(
                self.player.y - y
            )

            if distance_x < 150 and distance_y < 150:
                continue

            valid_position = True

            for frog in self.frogs:

                distance_x = abs(
                    frog.x - x
                )

                distance_y = abs(
                    frog.y - y
                )

                if distance_x < 100 and distance_y < 100:

                    valid_position = False
                    break

            if valid_position:
                return Frog(x, y)

        return None

    def update(self, clock):

        delta_time = clock.get_time()

        self.game_time += delta_time

        self.player.update(clock)

        for frog in self.frogs:
            frog.update(clock)

        self.spawn_timer += delta_time

        if (
            len(self.frogs) <= self.min_frogs
            and self.spawn_timer >= self.spawn_interval
            and len(self.frogs) < self.max_frogs
        ):

            new_frog = self.create_frog()

            if new_frog:

                self.frogs.append(new_frog)

                self.spawn_timer = 0

                self.spawn_interval = random.randint(
                    300,
                    700
                )

    def is_finished(self):

        return self.game_time >= self.game_duration

    def draw_frog_prompt(self, screen, frog):

        distance_x = abs(
            self.player.x - frog.x
        )

        distance_y = abs(
            self.player.y - frog.y
        )

        if distance_x < 80 and distance_y < 80:

            self.draw_text_with_outline(
                screen,
                "Pressione E",
                (
                    frog.x + frog.idle[0].get_width() // 2,
                    frog.y - 15
                ),
                (255, 255, 255)
            )

    def draw_text_with_outline(
        self,
        screen,
        text,
        center,
        text_color
    ):

        outline_color = (80, 60, 40)

        outline = self.font.render(
            text,
            True,
            outline_color
        )

        text_surface = self.font.render(
            text,
            True,
            text_color
        )

        text_rect = text_surface.get_rect(
            center=center
        )

        outline_positions = [
            (-1, 0),
            (1, 0),
            (0, -1),
            (0, 1)
        ]

        for offset_x, offset_y in outline_positions:

            outline_rect = text_rect.move(
                offset_x,
                offset_y
            )

            screen.blit(
                outline,
                outline_rect
            )

        screen.blit(
            text_surface,
            text_rect
        )

    def draw_counter(self, screen):

        screen.blit(
            self.counter_background,
            (10, 10)
        )

        screen.blit(
            self.frog_icon,
            (38, 27)
        )

        self.draw_text_with_outline(
            screen,
            str(self.frogs_caught),
            (95, 49),
            (255, 255, 255)
        )

    def draw_timer(self, screen):

        remaining_time = max(
            0,
            self.game_duration - self.game_time
        )

        seconds = int(remaining_time / 1000)

        minutes = seconds // 60
        seconds = seconds % 60

        time_text = f"{minutes:02d}:{seconds:02d}"

        screen.blit(
            self.counter_background,
            (self.width - 150, 10)
        )

        if remaining_time <= 10000:
            text_color = (190, 55, 55)
        else:
            text_color = (255, 255, 255)

        self.draw_text_with_outline(
            screen,
            time_text,
            (self.width - 78, 50),
            text_color
        )

    def draw(self, screen):

        screen.blit(
            self.background,
            (0, 0)
        )

        for frog in self.frogs:

            frog.draw(screen)

            self.draw_frog_prompt(
                screen,
                frog
            )

        self.player.draw(screen)

        self.draw_counter(screen)

        self.draw_timer(screen)