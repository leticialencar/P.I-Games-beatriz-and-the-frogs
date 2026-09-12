import pygame
import random

from utils import resource_path

class LoadingScreen:

    def __init__(self, width, height):

        self.width = width
        self.height = height

        self.font_text = pygame.font.Font(
            resource_path("assets/fonts/Minecraftia-Regular.ttf"),
            14
        )

        self.messages = [
            "Beatriz vai com ou sem falta porque ela não perde um bingo.",
            "Beatriz é formada em arquitetura no The Sims 4.",
            "Não, Igor. Letícia não vai raspar o cabelo nem arrancar as unhas para jogar.",
            "Lembrete: Lucas é PJ. Para ele, 10h da manhã ainda é cedo.",
            "Curiosidade: o menor sapo conhecido cabe na ponta de um dedo.",
            "\"A gente não vai usar uma bazuca pra matar uma formiga.\" — Alexsandro, 2026",
            "Vem pro São João da FAP, Beatriz.",
            "Fabrício, por favor, traga o esparadrapo.",
            "Será que o mouse de Igor desconectou de novo?",
            "Lucas está trabalhando. É sério.",
            "Será que o Fabrício trouxe o esparadrapo?",
            "Simpatia: onde Igor quase secou a maionese temperada.",
            "Tadeu já foi revivido hoje?",
            "Curiosidade: Igor trocou de curso, mas o PI de Engenharia foi atrás dele.",
            "Será que a AraujoSat está funcionando hoje?",
            "Ramon é o professor favorito de Igor, Lucas e Beatriz.",
            "Não existe crise financeira que impeça uma Bulldog.",
            "Você sabia? Tadeu possui três netas: Evelyn, Beatriz e Letícia.",
            "Curiosidade: o \"vou já\" do Gabriel pode durar até duas horas.",
            "Você sabia? A virada de 2026 para 2027 vai ser six seven.",
        ]

        self.available_messages = self.messages.copy()

        random.shuffle(
            self.available_messages
        )

        self.message = self.available_messages.pop()

        self.progress = 0

        self.message_timer = pygame.time.get_ticks()
        self.message_delay = 2500

        self.start_time = pygame.time.get_ticks()

        self.duration = 15000

        self.frog_frames = []

        self.load_frog()

        self.frog_frame = 0
        self.frog_animation_timer = 0
        self.frog_frame_duration = 150

    def load_frog(self):

        sprite_sheet = pygame.image.load(
            resource_path("assets/frog/frog_spritesheet.png")
        ).convert_alpha()

        walk_rects = [
            (65, 424, 198, 176),
            (308, 424, 204, 173),
            (547, 424, 204, 176),
            (802, 429, 196, 171),
            (1046, 428, 200, 173),
            (1281, 428, 206, 169)
        ]

        scale = 0.18

        for rect in walk_rects:

            frame = sprite_sheet.subsurface(
                rect
            ).copy()

            width = int(
                frame.get_width() * scale
            )

            height = int(
                frame.get_height() * scale
            )

            frame = pygame.transform.scale(
                frame,
                (width, height)
            )

            self.frog_frames.append(
                frame
            )

    def update(self, clock):

        current_time = pygame.time.get_ticks()

        elapsed = current_time - self.start_time

        self.progress = min(
            elapsed / self.duration,
            1
        )

        if current_time - self.message_timer >= self.message_delay:

            if self.available_messages:

                self.message = self.available_messages.pop()

            self.message_timer = current_time

        delta_time = clock.get_time()

        self.frog_animation_timer += delta_time

        if self.frog_animation_timer >= self.frog_frame_duration:

            self.frog_animation_timer = 0

            self.frog_frame += 1

            if self.frog_frame >= len(self.frog_frames):

                self.frog_frame = 0

        return self.progress >= 1

    def draw(self, screen):

        screen.fill((0, 0, 0))

        message = self.font_text.render(
            self.message,
            True,
            (255, 255, 255)
        )

        message_rect = message.get_rect(
            center=(
                self.width // 2,
                280
            )
        )

        screen.blit(
            message,
            message_rect
        )

        bar_width = 400
        bar_height = 20

        bar_x = (
            self.width - bar_width
        ) // 2

        bar_y = 340

        pygame.draw.rect(
            screen,
            (80, 80, 80),
            (
                bar_x,
                bar_y,
                bar_width,
                bar_height
            )
        )

        progress_width = int(
            bar_width * self.progress
        )

        pygame.draw.rect(
            screen,
            (255, 255, 255),
            (
                bar_x,
                bar_y,
                progress_width,
                bar_height
            )
        )

        frog = self.frog_frames[
            self.frog_frame
        ]

        frog_x = (
            bar_x
            + (bar_width * self.progress)
            - frog.get_width() // 2
        )

        frog_y = (
            bar_y
            + (bar_height - frog.get_height()) // 2
        )

        screen.blit(
            frog,
            (
                frog_x,
                frog_y
            )
        )