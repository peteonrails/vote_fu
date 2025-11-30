import { application } from "./application"

import VoteFuController from "./vote_fu_controller"
import VoteFuStarsController from "./vote_fu_stars_controller"
import VoteFuReactionsController from "./vote_fu_reactions_controller"

application.register("vote-fu", VoteFuController)
application.register("vote-fu-stars", VoteFuStarsController)
application.register("vote-fu-reactions", VoteFuReactionsController)
