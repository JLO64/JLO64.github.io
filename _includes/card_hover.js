function addAnimation(elements, animation) {
    elements.forEach(item => {
      item.addEventListener('animationend', () => {
        item.style.animation = animation;
      });
      item.addEventListener('mouseleave', () => {
        item.style.animation = '';
      });
    });
  }
  
  addAnimation(document.querySelectorAll('.post-list-item'), 'card_breathe 0.5s infinite alternate linear');
  addAnimation(document.querySelectorAll('.project-box'), 'card_breathe 0.5s infinite alternate linear');
  addAnimation(document.querySelectorAll('.table-of-contents'), 'card_breathe 0.5s infinite alternate linear');
  addAnimation(document.querySelectorAll('.homepage-mastodon-post'), 'mastodon_card_breathe 0.5s infinite alternate linear');
  addAnimation(document.querySelectorAll('.hardcover-book-item'), 'card_breathe 0.5s infinite alternate linear');