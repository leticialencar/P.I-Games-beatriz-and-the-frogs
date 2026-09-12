import math
import pygame

from utils import resource_path

class MainMenu:

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
            16
        )

        self.small_font = pygame.font.Font(
            resource_path("assets/fonts/Minecraftia-Regular.ttf"),
            12
        )

        self.logo = pygame.image.load(
            resource_path("assets/ui/frog_hunt_logo.png")
        ).convert_alpha()

        logo_width = 350

        logo_height = int(
            self.logo.get_height()
            * (logo_width / self.logo.get_width())
        )

        self.logo = pygame.transform.smoothscale(
            self.logo,
            (
                logo_width,
                logo_height
            )
        )

        self.button_sound = pygame.mixer.Sound(
            resource_path("assets/sounds/button_click.wav")
        )

        self.button_sound.set_volume(0.7)

        self.selected_option = 0

        self.options = [
            "Jogar",
            "Sair"
        ]

        self.time_elapsed = 0

        self.icon_radius = 14

        self.show_lore = False

        self.lore_text = (
            "De Barbalha para o mundo, Beatriz, ou Bea para os mais "
            "próximos, é uma das três netas de Tadeu e uma caçadora "
            "de sapinhos que nunca recusa um bingo. "
            "Dizem que ela consegue encontrar qualquer sapinho... "
            "desde que não esteja ocupada marcando a cartela."
        )

    def _get_panel_rect(self):

        panel_width = 440
        panel_height = 500

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

        return panel_rect

    def _get_icon_rect(self):

        panel_rect = self._get_panel_rect()

        icon_center = (
            panel_rect.right - 34,
            panel_rect.top + 34
        )

        icon_rect = pygame.Rect(
            0,
            0,
            self.icon_radius * 2,
            self.icon_radius * 2
        )

        icon_rect.center = icon_center

        return icon_rect

    def handle_event(self, event):

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:

            if self._get_icon_rect().collidepoint(event.pos):

                self.button_sound.play()

                self.show_lore = not self.show_lore

            elif self.show_lore:

                self.button_sound.play()

                self.show_lore = False

        if event.type == pygame.KEYDOWN:

            if self.show_lore:

                if event.key in (
                    pygame.K_ESCAPE,
                    pygame.K_RETURN
                ):

                    self.button_sound.play()

                    self.show_lore = False

                return None

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

                    return "play"

                if self.selected_option == 1:

                    return "quit"

        return None

    def update(self, clock):

        self.time_elapsed += clock.get_time() / 1000

    def wrap_text(self, text, font, max_width):

        words = text.split(" ")
        lines = []
        current_line = ""

        for word in words:

            test_line = f"{current_line} {word}".strip()

            if font.size(test_line)[0] <= max_width:

                current_line = test_line

            else:

                if current_line:

                    lines.append(current_line)

                current_line = word

        if current_line:

            lines.append(current_line)

        return lines

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

        panel_rect = self._get_panel_rect()

        panel_width = panel_rect.width
        panel_height = panel_rect.height

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

    def draw_lore_icon(self, screen):

        icon_rect = self._get_icon_rect()

        pygame.draw.circle(
            screen,
            (25, 20, 15),
            icon_rect.center,
            self.icon_radius
        )

        pygame.draw.circle(
            screen,
            (255, 214, 140),
            icon_rect.center,
            self.icon_radius,
            width=2
        )

        self.draw_text_with_outline(
            screen,
            "?",
            self.small_font,
            icon_rect.center,
            (255, 224, 150)
        )

    def draw_lore_popup(self, screen):

        overlay = pygame.Surface(
            (self.width, self.height),
            pygame.SRCALPHA
        )

        overlay.fill(
            (0, 0, 0, 160)
        )

        screen.blit(
            overlay,
            (0, 0)
        )

        popup_width = 380
        popup_height = 290

        popup = pygame.Surface(
            (popup_width, popup_height),
            pygame.SRCALPHA
        )

        popup.fill(
            (30, 24, 16, 235)
        )

        popup_rect = popup.get_rect(
            center=(
                self.width // 2,
                self.height // 2
            )
        )

        screen.blit(
            popup,
            popup_rect
        )

        pygame.draw.rect(
            screen,
            (255, 214, 140),
            popup_rect,
            width=2,
            border_radius=12
        )

        self.draw_text_with_outline(
            screen,
            "Quem é a Bea?",
            self.font,
            (
                self.width // 2,
                popup_rect.top + 38
            ),
            (255, 224, 150)
        )

        lines = self.wrap_text(
            self.lore_text,
            self.small_font,
            popup_width - 60
        )

        line_height = 22
        start_y = popup_rect.top + 82

        for index, line in enumerate(lines):

            self.draw_text_with_outline(
                screen,
                line,
                self.small_font,
                (
                    self.width // 2,
                    start_y + index * line_height
                ),
                (255, 255, 255)
            )

        self.draw_text_with_outline(
            screen,
            "Clique para fechar",
            self.small_font,
            (
                self.width // 2,
                popup_rect.bottom - 34
            ),
            (150, 150, 150)
        )

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

            arrow = self.font.render(
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
            self.font,
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

        logo_center = (
            self.width // 2,
            panel_rect.top + 150
        )

        glow_radius = 130

        glow = pygame.Surface(
            (
                glow_radius * 2,
                glow_radius * 2
            ),
            pygame.SRCALPHA
        )

        for r in range(
            glow_radius,
            0,
            -2
        ):

            alpha = int(
                25 * (
                    1 - r / glow_radius
                )
            )

            pygame.draw.circle(
                glow,
                (255, 240, 180, alpha),
                (
                    glow_radius,
                    glow_radius
                ),
                r
            )

        glow_rect = glow.get_rect(
            center=logo_center
        )

        screen.blit(
            glow,
            glow_rect
        )

        logo_rect = self.logo.get_rect(
            center=logo_center
        )

        screen.blit(
            self.logo,
            logo_rect
        )

        self.draw_lore_icon(
            screen
        )

        self.draw_option(
            screen,
            "Jogar",
            (
                self.width // 2,
                panel_rect.top + 320
            ),
            self.selected_option == 0
        )

        self.draw_option(
            screen,
            "Sair",
            (
                self.width // 2,
                panel_rect.top + 380
            ),
            self.selected_option == 1
        )

        self.draw_text_with_outline(
            screen,
            "Use ↑ ↓ e Enter",
            self.small_font,
            (
                self.width // 2,
                panel_rect.bottom - 25
            ),
            (150, 150, 150)
        )

        if self.show_lore:

            self.draw_lore_popup(
                screen
            )