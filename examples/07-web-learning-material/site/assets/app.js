(function () {
  'use strict';

  var courseId = document.body.dataset.courseId || 'web-course';
  var storageKey = 'web-learning:' + courseId + ':completed';
  var completed = readCompleted();

  document.querySelectorAll('.skip-link').forEach(function (link) {
    link.addEventListener('click', function () {
      var main = document.querySelector('#main');
      if (main) {
        window.setTimeout(function () {
          main.focus();
        }, 0);
      }
    });
  });

  function readCompleted() {
    try {
      var value = JSON.parse(window.localStorage.getItem(storageKey) || '[]');
      return new Set(Array.isArray(value) ? value.filter(function (item) {
        return typeof item === 'string';
      }) : []);
    } catch (error) {
      return new Set();
    }
  }

  function saveCompleted() {
    try {
      window.localStorage.setItem(storageKey, JSON.stringify(Array.from(completed)));
      return true;
    } catch (error) {
      return false;
    }
  }

  function updateProgress() {
    var progress = document.querySelector('[data-course-progress]');
    var progressText = document.querySelector('[data-progress-text]');

    if (progress) {
      progress.value = Math.min(completed.size, Number(progress.max));
    }
    if (progressText) {
      progressText.textContent = '已完成 ' + completed.size + '／' + progressText.dataset.total + ' 課';
    }

    document.querySelectorAll('[data-completion-state]').forEach(function (state) {
      var isComplete = completed.has(state.dataset.completionState);
      state.textContent = isComplete ? '已完成' : '尚未完成';
    });
  }

  document.querySelectorAll('[data-course-progress]').forEach(function (progress) {
    var progressText = document.querySelector('[data-progress-text]');
    if (progressText) {
      progressText.dataset.total = progress.max;
    }
  });

  document.querySelectorAll('[data-completion-id]').forEach(function (button) {
    var lessonId = button.dataset.completionId;
    var message = document.querySelector('[data-completion-message]');

    function renderButton() {
      var isComplete = completed.has(lessonId);
      button.setAttribute('aria-pressed', String(isComplete));
      button.textContent = isComplete ? '取消完成標記' : '標記為完成';
      if (message) {
        message.textContent = isComplete ? '本課已計入學習進度。' : '完成練習後再標記本課。';
      }
    }

    button.addEventListener('click', function () {
      if (completed.has(lessonId)) {
        completed.delete(lessonId);
      } else {
        completed.add(lessonId);
      }

      var saved = saveCompleted();
      renderButton();
      updateProgress();
      if (!saved && message) {
        message.textContent += ' 瀏覽器未允許儲存，重新整理後狀態可能消失。';
      }
    });

    renderButton();
  });

  updateProgress();
}());
