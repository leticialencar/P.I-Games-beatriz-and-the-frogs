import math
import pygame

from utils import resource_path

class EndGame:

    def __init__(
        self,
        width,
        height,
        frogs_caught,
        game_time
    ):

        self.width = width
        self.height = height

        self.frogs_caught = frogs_caught
        self.game_time = game_time

        self.background = pygame.image.load(
            resource_path("assets/background/background.png")
        ).convert()
        
        self.background = pygame.transform.scale(
            self.background,
            (self.width, self.height)
        )

        self.font = pygame.font.Font(
            resource_path("assets/fonts/Minecraftia-Regular.ttf"),
            16
        )

        self.option_font = pygame.font.Font(
            resource_path("assets/fonts/Minecraftia-Regular.ttf"),
            14
        )

        self.small_font = pygame.font.Font(
            resource_path("assets/fonts/Minecraftia-Regular.ttf"),
            12
        )

        self.stats_font = pygame.font.Font(
            resource_path("assets/fonts/Minecraftia-Regular.ttf"),
            14
        )

        self.title_font = pygame.font.Font(
            resource_path("assets/fonts/Minecraftia-Regular.ttf"),
            24
        )

        if self.frogs_caught == 0:

            self.animation_sheet = pygame.image.load(
                resource_path("assets/player/bea_sad.png")
            ).convert_alpha()

        else:

            self.animation_sheet = pygame.image.load(
                resource_path("assets/player/bea_celebrate.png")
            ).convert_alpha()

        self.frame_width = (
            self.animation_sheet.get_width() // 4
        )

        self.frame_height = (
            self.animation_sheet.get_height()
        )

        self.frames = []

        for i in range(4):

            frame = self.animation_sheet.subsurface(
                (
                    i * self.frame_width,
                    0,
                    self.frame_width,
                    self.frame_height
                )
            )

            frame = pygame.transform.smoothscale(
                frame,
                (
                    int(self.frame_width * 0.25),
                    int(self.frame_height * 0.25)
                )
            )

            self.frames.append(frame)

        self.current_frame = 0

        self.animation_sequence = [
            0,
            1,
            2,
            1,
            0
        ]

        self.sequence_index = 0
        self.animation_timer = 0

        if self.frogs_caught == 0:

            self.animation_speed = 250

        else:

            self.animation_speed = 180

        self.selected_option = 0

        self.options = [
            "Jogar Novamente",
            "Voltar ao Menu",
            "Sair"
        ]

        self.time_elapsed = 0

        self.button_sound = pygame.mixer.Sound(
            "assets/sounds/button_click.wav"
        )

        self.button_sound.set_volume(0.7)

    def handle_event(self, event):

        if event.type == pygame.KEYDOWN:

            if event.key == pygame.K_UP:

                self.selected_option -= 1

                if self.selected_option < 0:

                    self.selected_option = (
                        len(self.options) - 1
                    )

            elif event.key == pygame.K_DOWN:

                self.selected_option += 1

                if self.selected_option >= len(
                    self.options
                ):

                    self.selected_option = 0

            elif event.key == pygame.K_RETURN:

                self.button_sound.play()

                if self.selected_option == 0:
                    return "game"

                if self.selected_option == 1:
                    return "menu"

                if self.selected_option == 2:
                    return "quit"

        return None

    def update(self, clock):

        delta_time = clock.get_time()

        self.time_elapsed += delta_time / 1000

        self.animation_timer += delta_time

        if self.sequence_index == 0:

            frame_duration = 500

        elif self.sequence_index == 2:

            frame_duration = 400

        elif self.sequence_index == 4:

            frame_duration = 500

        else:

            frame_duration = self.animation_speed

        if self.animation_timer >= frame_duration:

            self.animation_timer = 0

            self.sequence_index += 1

            if self.sequence_index >= len(
                self.animation_sequence
            ):

                self.sequence_index = 0

            self.current_frame = (
                self.animation_sequence[
                    self.sequence_index
                ]
            )

    def draw_text_with_outline(
        self,
        screen,
        text,
        font,
        center,
        text_color=(255, 255, 255),
        outline_color=(60, 45, 30)
    ):

        outline = font.render(
            text,
            True,
            outline_color
        )

        text_surface = font.render(
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
            (0, 1),
            (-1, -1),
            (1, -1),
            (-1, 1),
            (1, 1)
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

    def draw_panel(self, screen):

        panel_width = 440
        panel_height = 480

        panel_rect = pygame.Rect(
            0,
            0,
            panel_width,
            panel_height
        )

        panel_rect.center = (
            self.width // 2,
            self.height // 2
        )

        shadow = pygame.Surface(
            (panel_width + 16, panel_height + 16),
            pygame.SRCALPHA
        )

        pygame.draw.rect(
            shadow,
            (0, 0, 0, 90),
            shadow.get_rect(),
            border_radius=26
        )

        shadow_rect = shadow.get_rect(
            center=(
                panel_rect.centerx,
                panel_rect.centery + 6
            )
        )

        screen.blit(
            shadow,
            shadow_rect
        )

        panel = pygame.Surface(
            (panel_width, panel_height),
            pygame.SRCALPHA
        )

        top_color = (35, 27, 18, 170)
        bottom_color = (20, 16, 10, 190)

        for y in range(panel_height):

            t = y / panel_height

            color = (
                int(
                    top_color[0]
                    + (bottom_color[0] - top_color[0]) * t
                ),
                int(
                    top_color[1]
                    + (bottom_color[1] - top_color[1]) * t
                ),
                int(
                    top_color[2]
                    + (bottom_color[2] - top_color[2]) * t
                ),
                int(
                    top_color[3]
                    + (bottom_color[3] - top_color[3]) * t
                )
            )

            pygame.draw.line(
                panel,
                color,
                (0, y),
                (panel_width, y)
            )

        mask = pygame.Surface(
            (panel_width, panel_height),
            pygame.SRCALPHA
        )

        pygame.draw.rect(
            mask,
            (255, 255, 255, 255),
            mask.get_rect(),
            border_radius=24
        )

        panel.blit(
            mask,
            (0, 0),
            special_flags=pygame.BLEND_RGBA_MIN
        )

        screen.blit(
            panel,
            panel_rect
        )

        pygame.draw.rect(
            screen,
            (255, 214, 140),
            panel_rect,
            width=2,
            border_radius=24
        )

        inner_rect = panel_rect.inflate(
            -10,
            -10
        )

        pygame.draw.rect(
            screen,
            (120, 85, 45),
            inner_rect,
            width=2,
            border_radius=18
        )

        return panel_rect

    def draw_option(
        self,
        screen,
        text,
        center,
        selected
    ):

        if selected:

            pulse = (
                math.sin(self.time_elapsed * 4) + 1
            ) / 2

            highlight_width = 260
            highlight_height = 36

            highlight = pygame.Surface(
                (
                    highlight_width,
                    highlight_height
                ),
                pygame.SRCALPHA
            )

            alpha = int(
                60 + pulse * 40
            )

            pygame.draw.rect(
                highlight,
                (255, 200, 100, alpha),
                highlight.get_rect(),
                border_radius=14
            )

            pygame.draw.rect(
                highlight,
                (255, 220, 150, 160),
                highlight.get_rect(),
                width=1,
                border_radius=14
            )

            highlight_rect = highlight.get_rect(
                center=center
            )

            screen.blit(
                highlight,
                highlight_rect
            )

            text_color = (
                255,
                230,
                150
            )

            arrow_offset = int(
                pulse * 4
            )

            arrow = self.option_font.render(
                ">",
                True,
                (255, 230, 150)
            )

            arrow_rect = arrow.get_rect(
                midright=(
                    center[0] - 105 + arrow_offset,
                    center[1]
                )
            )

            screen.blit(
                arrow,
                arrow_rect
            )

        else:

            text_color = (
                220,
                220,
                220
            )

        self.draw_text_with_outline(
            screen,
            text,
            self.option_font,
            center,
            text_color
        )

    def draw(self, screen):

        screen.blit(
            self.background,
            (0, 0)
        )

        panel_rect = self.draw_panel(
            screen
        )

        if self.frogs_caught == 0:

            title = "Fim de jogo..."

        else:

            title = "Fim de jogo!"

        self.draw_text_with_outline(
            screen,
            title,
            self.title_font,
            (
                self.width // 2,
                panel_rect.top + 40
            ),
            (255, 255, 255)
        )

        frame = self.frames[
            self.current_frame
        ]

        frame_rect = frame.get_rect(
            center=(
                self.width // 2,
                panel_rect.top + 145
            )
        )

        screen.blit(
            frame,
            frame_rect
        )

        stats_y = panel_rect.top + 265

        self.draw_text_with_outline(
            screen,
            f"Sapinhos: {self.frogs_caught}",
            self.stats_font,
            (
                self.width // 2,
                stats_y
            ),
            (255, 255, 255)
        )

        if self.frogs_caught == 0:

            message = "Nenhum sapinho dessa vez."

        else:

            message = "Obrigado por jogar!"

        self.draw_text_with_outline(
            screen,
            message,
            self.small_font,
            (
                self.width // 2,
                stats_y + 28
            ),
            (255, 255, 255)
        )

        self.draw_option(
            screen,
            "Jogar Novamente",
            (
                self.width // 2,
                panel_rect.top + 345
            ),
            self.selected_option == 0
        )

        self.draw_option(
            screen,
            "Voltar ao Menu",
            (
                self.width // 2,
                panel_rect.top + 395
            ),
            self.selected_option == 1
        )

        self.draw_option(
            screen,
            "Sair",
            (
                self.width // 2,
                panel_rect.top + 445
            ),
            self.selected_option == 2
        )