import pygame
from utils import resource_path

class Player:

    def __init__(self, x, y, screen_width, screen_height):

        self.x = x
        self.y = y

        self.screen_width = screen_width
        self.screen_height = screen_height

        self.speed = 4

        self.current_frame = 0
        self.animation_timer = 0

        self.direction = "front"
        self.facing_right = True
        self.moving = False

        self.frame_duration = 150

        sprite_sheet = pygame.image.load(
            resource_path("assets/player/bea_spritesheet.png")
        ).convert_alpha()

        frame_width = 200
        frame_height = 218

        self.idle_front = []
        self.walk_front = []
        self.idle_side = []
        self.walk_side = []
        self.idle_back = []
        self.walk_back = []

        for i in range(2):

            frame = sprite_sheet.subsurface(
                pygame.Rect(
                    i * frame_width,
                    0,
                    frame_width,
                    frame_height
                )
            )

            frame = pygame.transform.scale(
                frame,
                (100, 109)
            )

            self.idle_front.append(frame)

        for i in range(6):

            frame = sprite_sheet.subsurface(
                pygame.Rect(
                    i * frame_width,
                    frame_height + 5,
                    frame_width,
                    frame_height - 5
                )
            )

            frame = pygame.transform.scale(
                frame,
                (100, 109)
            )

            self.walk_front.append(frame)

        for i in range(2):

            frame = sprite_sheet.subsurface(
                pygame.Rect(
                    i * frame_width,
                    frame_height * 2,
                    frame_width,
                    frame_height
                )
            )

            frame = pygame.transform.scale(
                frame,
                (100, 109)
            )

            self.idle_side.append(frame)

        for i in range(6):

            frame = sprite_sheet.subsurface(
                pygame.Rect(
                    i * frame_width,
                    frame_height * 3,
                    frame_width,
                    frame_height - 10
                )
            )

            frame = pygame.transform.scale(
                frame,
                (100, 109)
            )

            self.walk_side.append(frame)

        for i in range(2):

            frame = sprite_sheet.subsurface(
                pygame.Rect(
                    i * frame_width,
                    frame_height * 4 - 10,
                    frame_width,
                    frame_height - 15
                )
            )

            frame = pygame.transform.scale(
                frame,
                (100, 109)
            )

            self.idle_back.append(frame)

        for i in range(6):

            frame = sprite_sheet.subsurface(
                pygame.Rect(
                    i * frame_width,
                    frame_height * 5 - 20,
                    frame_width,
                    frame_height - 20
                )
            )

            frame = pygame.transform.scale(
                frame,
                (100, 109)
            )

            self.walk_back.append(frame)

    def move(self):

        keys = pygame.key.get_pressed()

        self.moving = False

        if keys[pygame.K_LEFT] or keys[pygame.K_a]:
            self.x -= self.speed
            self.direction = "side"
            self.facing_right = False
            self.moving = True

        elif keys[pygame.K_RIGHT] or keys[pygame.K_d]:
            self.x += self.speed
            self.direction = "side"
            self.facing_right = True
            self.moving = True

        elif keys[pygame.K_UP] or keys[pygame.K_w]:
            self.y -= self.speed
            self.direction = "back"
            self.moving = True

        elif keys[pygame.K_DOWN] or keys[pygame.K_s]:
            self.y += self.speed
            self.direction = "front"
            self.moving = True

        self.x = max(0, min(self.x, self.screen_width - 100))
        self.y = max(0, min(self.y, self.screen_height - 109))

    def update(self, clock):

        self.move()

        if self.moving:

            self.animation_timer += clock.get_time()

            if self.animation_timer >= self.frame_duration:

                self.animation_timer = 0

                if self.direction == "front":
                    max_frames = len(self.walk_front)

                elif self.direction == "side":
                    max_frames = len(self.walk_side)

                else:
                    max_frames = len(self.walk_back)

                self.current_frame += 1

                if self.current_frame >= max_frames:
                    self.current_frame = 0

        else:

            self.current_frame = 0
            self.animation_timer = 0

    def draw(self, screen):

        if self.direction == "front":

            if self.moving:
                image = self.walk_front[self.current_frame]
            else:
                image = self.idle_front[0]

        elif self.direction == "side":

            if self.moving:
                image = self.walk_side[self.current_frame]
            else:
                image = self.idle_side[0]

            if self.facing_right:
                image = pygame.transform.flip(image, True, False)

        else:

            if self.moving:
                image = self.walk_back[self.current_frame]
            else:
                image = self.idle_back[0]

        screen.blit(image, (self.x, self.y))