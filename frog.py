import pygame
import random
from utils import resource_path

class Frog:

    def __init__(self, x, y):

        self.x = x
        self.y = y

        self.scale = 0.18

        self.idle_frame = 0
        self.walk_frame = 0
        self.action_frame = 0

        self.animation_timer = 0

        self.direction = random.choice([-1, 1])
        self.moving = False
        self.action_playing = False

        self.state_timer = 0
        self.state_duration = random.randint(1000, 3000)

        self.action_timer = random.randint(4000, 8000)

        self.speed = 1

        self.idle_frame_durations = [
            2000,
            500,
            800,
            1200
        ]

        self.walk_frame_duration = 150
        self.action_frame_duration = 150

        self.sprite_sheet = pygame.image.load(
            resource_path("assets/frog/frog_spritesheet.png")
        ).convert_alpha()

        self.idle = []
        self.walk = []
        self.action = []

        self.load_sprites()

    def load_sprites(self):

        idle_rects = [
            (174, 123, 201, 203),
            (500, 123, 202, 202),
            (824, 123, 200, 202),
            (1159, 121, 200, 208)
        ]

        walk_rects = [
            (65, 424, 198, 176),
            (308, 424, 204, 173),
            (547, 424, 204, 176),
            (802, 429, 196, 171),
            (1046, 428, 200, 173),
            (1281, 428, 206, 169)
        ]

        action_rects = [
            (174, 773, 207, 162),
            (494, 702, 239, 212),
            (802, 682, 214, 212),
            (1153, 781, 200, 159)
        ]

        for rect in idle_rects:

            frame = self.sprite_sheet.subsurface(rect).copy()

            width = int(frame.get_width() * self.scale)
            height = int(frame.get_height() * self.scale)

            frame = pygame.transform.scale(
                frame,
                (width, height)
            )

            self.idle.append(frame)

        for rect in walk_rects:

            frame = self.sprite_sheet.subsurface(rect).copy()

            width = int(frame.get_width() * self.scale)
            height = int(frame.get_height() * self.scale)

            frame = pygame.transform.scale(
                frame,
                (width, height)
            )

            self.walk.append(frame)

        for rect in action_rects:

            frame = self.sprite_sheet.subsurface(rect).copy()

            width = int(frame.get_width() * self.scale)
            height = int(frame.get_height() * self.scale)

            frame = pygame.transform.scale(
                frame,
                (width, height)
            )

            self.action.append(frame)

    def update(self, clock):

        delta_time = clock.get_time()

        if self.action_playing:

            self.animation_timer += delta_time

            if self.animation_timer >= self.action_frame_duration:

                self.animation_timer = 0

                self.action_frame += 1

                if self.action_frame >= len(self.action):

                    self.action_frame = 0
                    self.action_playing = False
                    self.action_timer = random.randint(4000, 8000)

            return

        self.action_timer -= delta_time

        if self.action_timer <= 0:

            self.action_playing = True
            self.action_frame = 0
            self.animation_timer = 0

            return

        self.state_timer += delta_time

        if self.state_timer >= self.state_duration:

            self.state_timer = 0

            self.moving = not self.moving

            self.state_duration = random.randint(1000, 3000)

            if self.moving:

                self.direction = random.choice([-1, 1])
                self.walk_frame = 0

            else:

                self.idle_frame = 0

        if self.moving:

            self.x += self.speed * self.direction

            if self.x <= 0:

                self.x = 0
                self.direction = 1

            elif self.x >= 800 - 40:

                self.x = 800 - 40
                self.direction = -1

            self.animation_timer += delta_time

            if self.animation_timer >= self.walk_frame_duration:

                self.animation_timer = 0

                self.walk_frame += 1

                if self.walk_frame >= len(self.walk):

                    self.walk_frame = 0

        else:

            self.animation_timer += delta_time

            if self.animation_timer >= self.idle_frame_durations[self.idle_frame]:

                self.animation_timer = 0

                self.idle_frame += 1

                if self.idle_frame >= len(self.idle):

                    self.idle_frame = 0

    def draw(self, screen):

        if self.action_playing:

            image = self.action[self.action_frame]

        elif self.moving:

            image = self.walk[self.walk_frame]

            if self.direction == -1:

                image = pygame.transform.flip(
                    image,
                    True,
                    False
                )

        else:

            image = self.idle[self.idle_frame]

        screen.blit(
            image,
            (self.x, self.y)
        )